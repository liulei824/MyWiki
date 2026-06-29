# PTO 异步通信 · URMA 后端

- **来源**: `code/pto-isa-main` 源码（`include/pto/comm/async/urma/`）整合
- **整理日期**: 2026-06-29
- **类型**: 自写综合笔记（完整知识正文）

> 覆盖：架构模型、核心数据结构、Host/Device 执行流程、硬件约束、与 SDMA 差异、多 Rank 寻址、源文件索引。
> 关联：[[comm-isa]]（通信 ISA 总览）、[[comm-async-sdma]]、[[comm-async-ccu]]、[[pto-overview]]

---

## 1. 架构概述

### 1.1 两层执行实体

```
┌──────────────────────────────────────────────────────────────┐
│ AI Core (标量/向量单元)                                       │
│   BuildAsyncSession、WQE 填写、doorbell、CQ 轮询             │
│   使用 ld_dev / st_dev / dcci（无需 UB scratch）             │
├──────────────────────────────────────────────────────────────┤
│ HCCP V2 / Jetty 硬件 (RDMA 引擎)                            │
│   从 Work Queue 消费 WQE，经 RDMA 完成 GM↔GM 传输           │
│   Completion Queue 回写 CQE                                  │
└──────────────────────────────────────────────────────────────┘
```

- AI Core 在 **PostSend 阶段即敲 doorbell**（与 SDMA「延迟到 Wait」不同）。
- Wait 通过 **轮询 CQ（CQE owner 位翻转）** 判断完成，不填 Flag SQE。
- 不依赖 MTE 管道做 GM↔UB 中转；**不需要 `scratchTile` / `syncId`**。

### 1.2 URMA 指令语义

| 指令 | 语义 | 数据流 | 底层 opcode |
|------|------|--------|-------------|
| `TPUT_ASYNC<URMA>` | 异步远程写 | 本地 GM → RDMA WRITE → 远端 GM | `UrmaOpcode::WRITE` |
| `TGET_ASYNC<URMA>` | 异步远程读 | 远端 GM → RDMA READ → 本地 GM | `UrmaOpcode::READ` |

核心特点：

- **非阻塞**：立即返回 `AsyncEvent`（handle 编码 `destRankId + curHead`）。
- **Quiet 语义**：多次 PostSend 后，`event.Wait(session)` 轮询 CQ 直到 `curHead` 对应 CQE 被消费。
- **仅支持扁平连续 1D tensor**（与 SDMA 路径相同校验）。
- **立即 doorbell**：每次 `UrmaPostSend` 后 `st_dev` 写 doorbell 并更新 SQ head。
- **按目标 rank 建 Session**：`BuildAsyncSession<URMA>(workspace, destRankId, session)`，`destRankId` 决定使用哪组 WQ/CQ 与哪行 `UrmaMemInfo`。

### 1.3 平台与编译条件

| 项 | 说明 |
|----|------|
| 编译宏 | `PTO_URMA_SUPPORTED`（通常 `__NPU_ARCH__ == 3510` / A5） |
| 适用平台 | A5 / NPU_ARCH 3510（HCCP V2 Jetty） |
| Host 依赖 | HCCP V2 动态库（`TsdProcessOpen`、`RaInit`、`RaCtxQpCreate` 等） |
| 与 SDMA 关系 | **并列后端**，编译期 `DmaEngine::URMA` 选择；A5 上 SDMA PUT 可能回退 MTE，URMA 为可选 RDMA 路径 |

### 1.4 与 SDMA 的关键差异（速查）

| 维度 | SDMA | URMA |
|------|------|------|
| 队列条目 | `BatchWriteItem` (64B SQE) | `UrmaSqeCtx` (48B) + `UrmaSgeCtx` (16B) WQE |
| doorbell | 延迟到 Wait | PostSend 后立即敲 |
| 完成同步 | Flag SQE + 轮询 `SdmaEventRecord` | 轮询 CQ `UrmaJfcCqeCtx` |
| UB scratch | 需要 `scratchTile` | 不需要 |
| Session 参数 | workspace + scratch + syncId + baseConfig | workspace + **destRankId** |
| 远端寻址 | HCCL `windowsIn[]` + offset | 对称 MR `UrmaMemInfo.addr` + token/EID |
| Host 建链 | `SdmaWorkspaceManager` + HCCL 窗口 | `UrmaWorkspaceManager` + bootstrap AllGather |

---

## 2. 核心常量与数据结构

### 2.1 常量速查

| 符号 | 值 | 说明 |
|------|-----|------|
| `kUrmaPollCqThreshold` | 10 | SQ 将满时触发 CQ 预 poll 的 head/tail 间距阈值 |
| `kUrmaMaxPollTimes` | 1,000,000 | CQ 轮询上限 |
| `kNumCqePerPollCq` | 100 | 预 poll 时一次消费的 CQE 数 |
| `kMaxSgeNumShift` | 2 | WQE `owner` 位计算用 |
| `kCacheLineSize` | 64 | `DcciCachelines` 粒度 |
| `kHandleRankIdShift` | 32 | AsyncEvent handle 高 32 位存 destRankId |
| `kSqDepthDefault` (HCCP) | 4096 | Jetty SQ 默认深度 |
| `kRqDepthDefault` (HCCP) | 256 | Jetty RQ 默认深度 |
| `kCqDepthDefault` (HCCP) | 16384 | CQ 默认深度 |
| `qpNum` (当前实现) | 1 | 每 rank 固定 1 个 QP |

### 2.2 Session / Context

```cpp
struct UrmaExecContext {
    __gm__ uint8_t *contextGm;  // UrmaInfo workspace 基址
    uint32_t destRankId;        // 目标 peer rank
    uint32_t qpIdx;             // QP 索引（当前固定 0）
};

struct UrmaEventContext {
    __gm__ uint8_t *contextGm;  // 与 execCtx 同一 workspace
};
```

`BuildUrmaSession` 同时填充 `execCtx` 与 `eventCtx` 的 `contextGm`；Wait/Test 仅使用 `eventCtx.contextGm`。

### 2.3 UrmaInfo — workspace 根头

```cpp
struct UrmaInfo {
    uint32_t qpNum;
    uint32_t localTokenId;   // 填 SGE.tokenId
    uint32_t rankCount;
    uint64_t sqPtr;          // → UrmaWQCtx[rankCount × qpNum]
    uint64_t rqPtr;          // → UrmaWQCtx[rankCount × qpNum]
    uint64_t scqPtr;         // → UrmaCqCtx[rankCount × qpNum]
    uint64_t rcqPtr;         // → UrmaCqCtx[rankCount × qpNum]
    uint64_t memPtr;         // → UrmaMemInfo[rankCount]
};
```

### 2.4 UrmaWQCtx / UrmaCqCtx — 队列描述符（workspace 内）

**UrmaWQCtx**（Send/Recv Queue）：

| 字段 | 说明 |
|------|------|
| `wqn` | WQ 编号 |
| `bufAddr` | **HCCP 分配的 SQ 环基址**（WQE 写在此处，不在 workspace blob 内） |
| `wqeShiftSize` | WQE 大小 = `2^shift`（SqeCtx 48B + SgeCtx 16B = 64B） |
| `depth` | 环深度 |
| `headAddr` / `tailAddr` | **独立 GM** 上的 PI/CI 计数器指针 |
| `dbMode` | `UrmaDbMode::SW_DB` |
| `dbAddr` | doorbell 地址 |
| `sl` | Service level |

**UrmaCqCtx**（Completion Queue）：

| 字段 | 说明 |
|------|------|
| `cqn` | CQ 编号 |
| `bufAddr` | **HCCP 分配的 CQE 环基址** |
| `cqeShiftSize` | CQE 大小 = `2^shift` |
| `depth` | 环深度 |
| `headAddr` / `tailAddr` | PI/CI 计数器（Wait 读 `tailAddr`） |
| `dbAddr` | CQ doorbell |

### 2.5 UrmaMemInfo — 各 peer 远端 MR 鉴权（workspace 内）

| 字段 | 说明 |
|------|------|
| `tokenValueValid` | 是否校验 token |
| `rmtJettyType` | 远端 Jetty 类型 |
| `targetHint` | 路由 hint |
| `tpn` | Transport path number（`JettyImport` 得到） |
| `tid` | Target segment / jetty id |
| `rmtTokenValue` | 远端 token |
| `len` | 对称 MR 大小 |
| `addr` | **该 peer 对称内存 device VA 基址** |
| `eidAddr` | 指向 `hccpEidDevice_` 中该 rank 的 EID |

### 2.6 WQE / CQE 布局

**UrmaSqeCtx (48B) + UrmaSgeCtx (16B)**，紧随排列于 SQ 环：

| UrmaSqeCtx 关键字段 | 说明 |
|---------------------|------|
| `sqeBbIdx` | WQE 环内索引 |
| `opcode` | WRITE / READ / SEND / CAS / FAA 等 |
| `flag` | 固定 `0b00100010` |
| `tokenEn` | 来自 `UrmaMemInfo.tokenValueValid` |
| `tpId` | 来自 `UrmaMemInfo.tpn` |
| `rmtJettyOrSegId` | 来自 `UrmaMemInfo.tid` |
| `rmtEidL/H` | 从 `eidAddr` 读取 |
| `rmtAddrL/H` | 远端 GM 地址（PUT=dst，GET=src） |

| UrmaSgeCtx 字段 | 说明 |
|-----------------|------|
| `len` | 传输字节数 |
| `tokenId` | `UrmaInfo.localTokenId` |
| `va` | 本地 GM 地址（PUT=src，GET=dst） |

**UrmaJfcCqeCtx**：CQ 完成条目；Wait 通过 `owner` 位翻转判断 CQE 有效。

---

## 3. Workspace 内存布局

### 3.1 workspace blob 内（`urmaInfoDevice_`）

Host `FillUrmaInfo()` 一次性分配并 H2D：

```
totalSize = sizeof(UrmaInfo)
          + rankCount × (2×sizeof(UrmaWQCtx)×qpNum
                         + 2×sizeof(UrmaCqCtx)×qpNum
                         + sizeof(UrmaMemInfo)×qpNum)
```

当前 `qpNum = 1` 时的逻辑布局：

```
urmaInfoDevice_ (GM)
├── UrmaInfo
│     qpNum, localTokenId, rankCount
│     sqPtr, rqPtr, scqPtr, rcqPtr, memPtr
├── [sqPtr]  UrmaWQCtx[rankCount]     — 各 peer 槽位的 SQ 描述
├── [rqPtr]  UrmaWQCtx[rankCount]     — 各 peer 槽位的 RQ 描述
├── [scqPtr] UrmaCqCtx[rankCount]     — Send CQ 描述
├── [rcqPtr] UrmaCqCtx[rankCount]     — Recv CQ 描述
└── [memPtr] UrmaMemInfo[rankCount]   — 各 peer MR 基址/token/EID 指针
```

`FillPerRankData` 对每个 rank 槽位写入：AllGather 后的 WQ/CQ 上下文 + 该 peer 的 `UrmaMemInfo` + `eidAddr`。

### 3.2 workspace 外（关联 GM 资源）

| 资源 | 分配时机 | 用途 |
|------|----------|------|
| SQ 环 / CQ 环 | HCCP `RaCtxQpCreate` / `RaCtxCqCreate` | `UrmaWQCtx.bufAddr` / `UrmaCqCtx.bufAddr` 仅保存指针 |
| `sqPiAddr_` / `sqCiAddr_` | Host `aclrtMalloc(4B)` ×2 | SQ head/tail |
| `cqPiAddr_` / `cqCiAddr_` | Host `aclrtMalloc(4B)` ×2 | CQ head/tail |
| `hccpEidDevice_` | Host `rankCount × 16B` | 各 rank EID 表 |
| **对称 payload** | 用户 `symmetricAddr`（如 `aclshmem_malloc`） | 实际通信数据；**不在 workspace 内** |
| HCCP 句柄 | Host 侧 only | `ctxHandle_`、`qpHandle_`、`remoteQpHandles_` 等 |

---

## 4. 执行流程

### 4.1 Host 完整 Workflow

```
UrmaWorkspaceManager::Init(deviceId, rankId, rankCount, symmetricAddr, symmetricSize, bootstrap)
  ①  TsdProcessOpen
  ②  RaInit
  ③  RaCtxInit (+ EID + TokenIdAlloc)
  ④  RaCtxLmemRegister          — 注册对称内存为 MR
  ⑤  RaCtxChanCreate + RaCtxCqCreate — CQ + PI/CI
  ⑥  RaCtxQpCreate               — Jetty QP + SQ PI/CI
  ⑦  JettyImport                 — AllGather QpKey + RaCtxQpImport
  ⑧  JettyBind                   — 非 RM 模式绑定远端 QP
  ⑨  FillUrmaInfo                 — 组装 UrmaInfo + aclrtMemcpy H2D
  ⑩  RmemImport                  — AllGather MR + RaCtxRmemImport
      ↓ GetWorkspaceAddr() 传入 kernel
Device:
  ① BuildAsyncSession<URMA>(workspace, destRankId, session)
  ② TPUT_ASYNC / TGET_ASYNC<URMA>(..., session)
  ③ event.Wait(session)          — UrmaPollCq 轮询 CQ
```

详细逐步接口与 Host 句柄管理见 `include/pto/comm/async/urma/urma_workspace_manager.hpp`（10 步初始化）与 `urma_workspace_helpers.hpp`。

### 4.2 Device：BuildAsyncSession

```cpp
BuildUrmaSession(contextGm, destRankId, session)
  → execCtx  = { contextGm, destRankId, qpIdx=0 }
  → eventCtx = { contextGm }
```

- **每个目标 peer 通常一个 session**（或按 peer 重建），因 `destRankId` 绑定 WQ/CQ/Mem 行索引。
- 不需要 `scratchTile`、`syncId`、`SdmaBaseConfig`。

### 4.3 发起传输：UrmaPostSend

```
1. 从 UrmaInfo 取 sqPtr[destRankId] → UrmaWQCtx
2. ld_dev head/tail；若将满则 UrmaPollCq 预消费
3. memPtr[destRankId] → UrmaMemInfo（token/tpn/EID/远端基址）
4. 在 bufAddr + (curHead % depth) × wqeSize 填写 UrmaSqeCtx + UrmaSgeCtx
5. DcciCachelines(WQE)
6. UrmaPostSendUpdateInfo：st_dev doorbell + 更新 head
7. return curHead → 编码进 AsyncEvent handle
```

PUT：`FillSqeCtx(..., remoteAddr=dst, SGE.va=src, opcode=WRITE)`  
GET：`FillSqeCtx(..., remoteAddr=src, SGE.va=dst, opcode=READ)`

**AsyncEvent handle 编码**：

```
handle = (destRankId << 32) | curHead
```

### 4.4 等待完成：UrmaWaitEvent

```
1. DecodeHandle → destRankId, curHead
2. UrmaPollCq(contextGm, destRankId, qpIdx=0, curHead)
     → 读 cqCtx.tailAddr 与 curHead 比较
     → 未完成：dcci + 轮询 CQE owner 位（最多 kUrmaMaxPollTimes）
     → 完成：更新 tail、UrmaPollCqUpdateInfo（CQ/SQ doorbell）
3. 返回 status/substatus == 0 表示成功
```

`UrmaTestEvent`：非阻塞检查 tail 或最后一个 CQE 的 owner 位。

### 4.5 远端地址计算

与 SDMA（HCCL `windowsIn[]`）不同，URMA 使用 **对称 MR**：

```cpp
// 某 peer 的对称内存基址（device VA）
uint64_t base = UrmaPeerMrBaseAddr(urmaWorkspace, peerRank);
// → memPtr[peerRank].addr

// 用户 buffer 通常已在 symmetric 区域内；跨 rank 访问时
// TPUT 的 dst 为远端 peer 区内偏移地址，由 UrmaMemInfo + WQE 远端字段表达
```

Demo（`allgather_urma_kernel.cpp`）模式：`UrmaPeerMrBaseAddr` + slot 偏移，替代 `CommRemotePtr`。

---

## 5. 硬件与编程约束

| 约束项 | 说明 |
|--------|------|
| **Tensor 布局** | 仅扁平连续逻辑一维（与 SDMA 相同断言） |
| **对称内存** | payload 须注册为 MR（`RaCtxLmemRegister`）；跨机 RDMA 需 `aclshmem_malloc` 类对称分配 |
| **bootstrap** | 必须提供 AllGather/Barrier（交换 WQ/CQ/MR/QPKey/EID） |
| **destRankId** | `< rankCount`；决定 WQ/CQ/Mem 行索引 |
| **qpIdx** | 当前固定 0 |
| **Cache 一致性** | PostSend / Poll 前对 WQE/CQE 做 `dcci` |
| **SQ 背压** | head 接近 tail 时自动 PollCq（阈值 `kUrmaPollCqThreshold`） |
| **无 UB scratch** | 不可假设有 MTE staging；与 SDMA 编程模型不同 |
| **编译目标** | 非 `PTO_URMA_SUPPORTED` 平台 URMA 指令被编译掉 |

---

## 6. Cost Model（概要）

> URMA 尚无独立 cost model 文档；以下为源码结构推导的 **定性分解**，数值待实测标定。

```
T_kernel ≈ T_build + T_post + T_wait

T_post ≈ t_ld_head_tail + t_fill_wqe + t_dcci + t_doorbell
T_wait ≈ T_rdma_transfer（与 poll 重叠）+ N_poll × (t_dcci + t_ld_cqe)
```

与 SDMA 对比：

| 阶段 | URMA | SDMA |
|------|------|------|
| Post | 立即 doorbell；无 MTE Get/Set | 批量 SQE；无 doorbell |
| Wait | 仅 CQ poll | Flag SQE + doorbell + EventRecord poll + MTE |
| 软件开销 | 较低（无 scratch） | 较高（MTE2/3 staging） |

---

## 7. 多 Rank 与 Session 策略

### 7.1 与 HCCL 的关系

| 路径 | 建域 | 远端寻址 |
|------|------|----------|
| SDMA + HCCL | `HcclCommInitRootInfo` + `HcclAllocComResourceByTiling` | `windowsIn[rank] + offset` |
| URMA | **不强制 HCCL**；`UrmaWorkspaceManager` + bootstrap | `UrmaMemInfo[peer].addr` + offset |

URMA 走 HCCP V2 独立建链（QP Import/Bind、MR Import），通过对称内存 + token/EID 完成 RDMA 鉴权。

### 7.2 Session 与 peer 映射

- `BuildAsyncSession<URMA>(workspace, destRankId, session)`：**一个 destRankId 对应一条 Jetty 通信上下文**。
- 向多个 peer 并发通信时：
  - 为每个 peer 构建独立 `AsyncSession`，或
  - 每次通信前用同一 session 对象重建（更新 `destRankId`）。
- Multi-core demo：`block_idx == peer` 本地 MTE 拷贝；`block_idx != peer` 对该 peer 的 session 做 `TPUT_ASYNC<URMA>`。

### 7.3 Direct AllGather（URMA 版）

参考 `demos/baseline/allgather_async/csrc/kernel/allgather_urma_kernel.cpp`：

- Launch `<<<nRanks, ...>>>`，每 block 负责一个 target peer。
- 与 SDMA 版结构相同，仅替换 workspace 与寻址 helper。

---

## 8. 关键设计决策

### 8.1 立即 doorbell vs SDMA 延迟 doorbell

URMA 每次 `UrmaPostSend` 后立即 `st_dev` doorbell，硬件马上拉取 WQE。Quiet 语义靠 **CQ 轮询** 保证多次 Post 全部完成，而非 Flag SQE 批次提交。

### 8.2 Exec/Event 共用 contextGm

URMA 的 `UrmaEventContext` **仅含 `contextGm`**（无独立 workspace 字段需求）：Wait 所需的 WQ/CQ/Mem 信息与 Post 相同，均从 `UrmaInfo` 解析。与 SDMA 不同——SDMA Wait 实际读 `execCtx.contextGm`，`eventCtx` 几乎未用。

### 8.3 Handle 编码 destRankId + curHead

`AsyncEvent.handle` 高 32 位 = `destRankId`，低 32 位 = PostSend 后的 SQ head。Wait 据此定位应 poll 到哪一条 CQE。

### 8.4 无 scratchTile

AICore 直驱路径使用 `ld_dev`/`st_dev` 访问 GM 中的 PI/CI 与 CQE，避免 MTE UB 中转，简化 Session 构建与 kernel 资源规划。

---

## 9. 源文件索引

| 文件 | 作用 |
|------|------|
| `include/pto/comm/async/urma/urma_types.hpp` | UrmaInfo、WQ/CQ/Mem、Sqe/Sge/Cqe 结构体与常量 |
| `include/pto/comm/async/urma/urma_hccp_types.hpp` | HCCP V2 ABI 常量与 Host 侧类型 |
| `include/pto/comm/async/urma/urma_async_intrin.hpp` | PostSend、PollCq、Wait/Test、BuildUrmaSession、`UrmaPeerMrBaseAddr` |
| `include/pto/comm/async/urma/urma_workspace_manager.hpp` | Host 10 步初始化 |
| `include/pto/comm/async/urma/urma_workspace_helpers.hpp` | Layout 计算、FillPerRankData、bootstrap 辅助 |
| `include/pto/comm/async/urma/urma_hccp_loader.hpp` | HCCP V2 动态库加载 |
| `include/pto/comm/async_common/async_types.hpp` | UrmaSession、UrmaExec/EventContext |
| `include/pto/comm/async_common/async_event_impl.hpp` | `BuildAsyncSession<URMA>`、`AsyncEvent::Wait/Test` |
| `include/pto/comm/a5/async/TPutAsync.hpp` | A5 上 TPUT_ASYNC SDMA/MTE/URMA 分发 |
| `include/pto/comm/a5/async/TGetAsync.hpp` | TGET_ASYNC URMA 分发 |
| `include/pto/comm/pto_comm_inst.hpp` | 公开 API |
| `demos/baseline/allgather_async/csrc/kernel/allgather_urma_kernel.cpp` | URMA Direct/Ring AllGather 示例 |

---

## 10. 相关文档索引

| 文档 / 代码 | 内容 |
|------|------|
| [[comm-async-sdma]] | SDMA 后端完整正文（对照阅读） |
| [[comm-async-ccu]] | CCU 集合通信后端 |
| `include/pto/comm/async/urma/urma_workspace_manager.hpp` | URMA Host 10 步初始化（原 host_side_setup §3） |
| `include/pto/comm/async_common/async_types.hpp` | UrmaSession / Context（原 session.md §2.3） |
| `include/pto/comm/async/urma/urma_types.hpp` | URMA WQE/CQE 格式（原 engine_sqe_comparison §3） |
| `code/pto-isa-main/demos/baseline/allgather_async/README.md` | AllGather Async demo（含 URMA 变体） |
| `code/pto-isa-main/tests/npu/a5/comm/st/testcase/tput_async_urma/` | URMA TPUT ST |
| `code/pto-isa-main/tests/npu/a5/comm/st/testcase/tget_async_urma/` | URMA TGET ST |

---

## 11. SDMA vs URMA 选型指南

| 场景 | 建议 |
|------|------|
| A2/A3，板内 / STARS SDMA 可用 | **SDMA**（默认 `DmaEngine::SDMA`） |
| A5，需标准 RDMA、已有 HCCP/shmem 对称内存栈 | **URMA** |
| A5，`TPUT_ASYNC` SDMA 回退 MTE、需真异步 PUT | 考虑 **URMA** 或调整 SDMA 路径 |
| 需要 `queue_num` 多 channel 条带化 | **SDMA**（URMA 当前 `qpNum=1`） |
| 不想管理 UB scratch | **URMA** |
| 已有 HCCL `windowsIn` 窗口、MC2 集成 | **SDMA** + HCCL 更顺 |
| 集合通信（Reduce/AllGather 硬件加速） | **CCU**（非 URMA/SDMA 点对点模型） |

---

## 12. 典型用法 sketch

```cpp
// Host（每 rank 一次）
UrmaWorkspaceManager urmaMgr;
urmaMgr.Init(deviceId, rankId, rankCount, symmetricAddr, symmetricSize, bootstrap);
void *urmaWorkspace = urmaMgr.GetWorkspaceAddr();

// Device kernel
pto::comm::AsyncSession session;
pto::comm::BuildAsyncSession<pto::comm::DmaEngine::URMA>(
    urmaWorkspace, destRankId, session);

auto event = pto::comm::TPUT_ASYNC<pto::comm::DmaEngine::URMA>(dstG, srcG, session);
event.Wait(session);
```

---

## 13. 已知限制与待补充

| 项 | 现状 |
|----|------|
| Cost model 量化 | 无独立文稿；§6 仅为定性分解 |
| `qpNum > 1` | 常量固定 1，未暴露多 QP 条带化 |
| `rqPtr` / `rcqPtr` 槽位 | Layout 已预留；Fill 时与 SQ/SCQ 同样写入本地 WQ/CQ 副本 |
| 文档-代码 | 以 `code/pto-isa-main/include/pto/comm/async/urma/` 为准 |
