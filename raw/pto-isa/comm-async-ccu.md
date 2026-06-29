# PTO 集合通信 · CCU 后端

- **来源**: `code/pto-isa-main` 源码（`include/pto/comm/async/ccu/`）+ 工作区 `docs/treduce-perf-analysis/` 整合
- **整理日期**: 2026-06-29
- **类型**: 自写综合笔记（完整知识正文）

> 覆盖：架构模型、PTO 指令映射、核心数据结构、Host/Device 执行流程、微码编程模型、硬件约束、与 SDMA/URMA/AIV 差异、源文件索引。
> 关联：[[comm-isa]]（通信 ISA 总览）、[[comm-async-sdma]]、[[comm-async-urma]]、[[pto-overview]]

---

## 1. 架构概述

### 1.1 三层协作实体

```
┌──────────────────────────────────────────────────────────────┐
│ AIV (AI Core 向量路径)                                        │
│   可选 TSTORE 写 input HBM；CkeTrigger 写 CKE MMIO slot     │
├──────────────────────────────────────────────────────────────┤
│ Host (HCCL + hcomm CCU 框架)                                 │
│   注册/编译/加载微码；Launch 注入 task 参数；管理 RDMA channel │
├──────────────────────────────────────────────────────────────┤
│ CCU 硬件 (Communication Compute Unit)                        │
│   解码预加载微码；ReadNb/WriteNb/LocalReduceNb 等           │
│   经内部 RDMA channel 完成跨 rank 搬运 + MS 上规约           │
└──────────────────────────────────────────────────────────────┘
```

- CCU **不是** AI Core 填 SQ/WQE 的 DMA 后端；与 SDMA/URMA 的 `DmaEngine` 路径并列，PTO 通过 **`CollEngine::CCU`** 接入。
- Device 侧 AIV 的核心动作是一次 **CKE gate MMIO 写**（`CkeTrigger`），唤醒已在 Host 侧 Launch 的 CCU 流。
- 数据搬运与规约由 **CCU 微码**自主执行；底层 RDMA 最终仍经 HCCP Jetty，但无需 AI Core 参与 WQE 填写。

### 1.2 PTO 指令语义

| 指令 | 默认引擎 | CCU 路径 | AIV 侧职责 |
|------|----------|----------|------------|
| `TREDUCE<CollEngine::CCU>` | `CollEngine::AIV` | CCU 硬件规约 | `CcuStoreTriggerSelf`：可选 TSTORE input → CKE trigger |
| `TGATHER<CollEngine::CCU>` | AIV | CCU 硬件 Gather | 同上 |
| `TSCATTER<CollEngine::CCU>` | AIV | CCU 硬件 Scatter | `CcuStoreTriggerRoot`：root 可选 TSTORE src → trigger |
| `TBROADCAST<CollEngine::CCU>` | AIV | CCU 硬件 Broadcast | 同上（root 写 src） |

调用约定（`pto_comm_inst.hpp`）：

- CCU 路径 **不使用** `AsyncSession` / `AsyncEvent`。
- 可变参数列表 **第一个** 必须是 `CcuTriggerContext`。
- 返回 `RecordEvent`（空事件占位）；完成同步靠 Host **`aclrtSynchronizeStream(ccuStream)`**。

核心特点：

- **预编译微码 + 运行时参数化**：算法在 Host `HcclCcuKernelRegister` 时由 `CcuRep` 翻译为微码；每次 Launch 注入地址/长度/token。
- **Gated 启动**：CCU 在 `WaitEvent(gateEvent_)` 阻塞，直到 AIV 写 CKE slot 释放 gate。
- **融合搬运与计算**：Reduce 在 CCU 内部 MS（SRAM）上执行 `LocalReduceNb`；大数据可分块（微码 `CCU_WHILE`，块大小 4096B）。
- **1D-mesh 集合**：当前 PTO 实现为 1D mesh（Reduce/Gather/Scatter/Broadcast），rank 数上限 `kMaxReduceRanks = 16`。

### 1.3 平台与依赖

| 项 | 说明 |
|----|------|
| 适用平台 | A5（含 CCU 硬件，`NPU_ARCH 3510`） |
| Host 依赖 | HCCL（建域、Channel、CcuKernel API）+ hcomm（`CcuKernel` / `CcuRep` 微码框架） |
| 链路协议 | `COMM_PROTOCOL_UBC_CTP`（CCU RDMA channel，底层映射 URMA QP） |
| 与 URMA 关系 | CCU channel 底层走 HCCP Jetty；**应用不直接调 URMA API** |

### 1.4 与 SDMA / URMA / AIV 速查

| 维度 | SDMA / URMA | CCU | CollEngine::AIV |
|------|-------------|-----|-----------------|
| 引擎枚举 | `DmaEngine` | `CollEngine::CCU` | `CollEngine::AIV`（默认） |
| 通信模型 | 点对点 PUT/GET | 集合（Reduce/Gather/Scatter/Broadcast） | 集合（TLOAD+计算+TSTORE） |
| Device 填队列 | AI Core 写 SQE/WQE | **不填**；AIV 写 CKE | AIV 完整软件路径 |
| Session 类型 | `AsyncSession` | `CcuTriggerContext` | 无 |
| Host 准备 | SDMA workspace / URMA QP | HCCL + 微码注册 | HCCL 窗口（可选） |
| 计算能力 | 纯搬运 | MS 上 Reduce | AIV 向量规约 |

---

## 2. 核心常量与数据结构

### 2.1 常量速查

| 符号 | 值 | 说明 |
|------|-----|------|
| `kCkeValidBit` | `1ULL << 63` | CKE slot payload 有效位 |
| `CCU_GATE_MASK` / `CCU_DONE_MASK` | `1u << 0` | 默认 gate/done 事件 mask |
| `kMaxReduceRanks` | 16 | 单 kernel 支持的最大 rank 数 |
| `CCU_GATE_ENV` | `"HCCL_PTO_GATE_REDUCE"` | gate 模式环境变量 |
| MS 块大小 | 4096 B | CCU 内部 Memory Space；大块分块粒度 |
| `RT_RES_TYPE_CCU_CKE` | 3 | `rtGetDevResAddress` 查询 CKE slot 的资源类型 |

### 2.2 CcuTriggerContext — Device 触发上下文

```cpp
struct CcuTriggerContext {
    uint64_t ckeSlotVA;        // CKE slot VA（rtGetDevResAddress）
    uint32_t mask;             // 16-bit 触发 mask
    uint32_t selfIdx;          // 本 rank 在 ParallelGroup 中的索引
    CcuInputSource inputSource; // HostManaged 或 AivStored
};
```

**CcuInputSource**：

| 值 | 含义 |
|----|------|
| `HostManaged` | Host 或前序 op 已写好 input HBM；AIV 只敲 CKE |
| `AivStored` | AIV 在 trigger 前 `TSTORE` 把 tile 写入 `parallelGroup[selfIdx]`（Reduce/Gather）或 root src（Scatter/Broadcast） |

### 2.3 CcuGateDescriptor — Host gate 发现

```cpp
struct CcuGateDescriptor {
    uint32_t dieId;     // 物理 die（通常 0 或 1）
    uint32_t ckeId;     // CKE 表项索引
    uint32_t mask;      // 16-bit signal mask
    uint64_t mmioAddr;  // TryGet 后 Host 填 rtGetDevResAddress 结果
};
```

- **Producer**：CCU kernel `GeneArgs()` → `ccu::Publish(rankId, dieId, ckeId, mask)`
- **Consumer**：Host ST / 框架 → `ccu::TryGet(rankId, &desc)` → `rtGetDevResAddress`

### 2.4 Kernel / Task 参数（Host 侧）

以 Reduce 为例（其它 collective 结构类似）：

**CcuReduceKernelArg**（注册时，决定微码签名）：

| 字段 | 说明 |
|------|------|
| `rankId`, `rankSize`, `rootId` | 拓扑 |
| `dataType`, `outputDataType`, `reduceOp` | 规约类型 |
| `gateMask`, `doneMask` | CKE 事件 mask |
| `payloadBytes` | payload 大小（参与 kernel signature） |
| `channels` | `HcclChannelAcquire` 得到的 CCU channel 列表 |

**CcuReduceTaskArg**（每次 Launch）：

| 字段 | 说明 |
|------|------|
| `inputAddr`, `outputAddr`, `length`, `token` | 本 rank buffer |
| `peerInput[]`, `peerOutput[]`, `peerToken[]` | 各 rank 地址（Host AllGather 后填入） |
| `peerCount` | rank 数 |

**GeneArgs 打包布局**（`PackPeerArgs`）：

```
[input_0..N-1, output_0..N-1, token_0..N-1, length]
```

CCU 微码 `LoadPeerArgs` 按此顺序 `Load` 到寄存器。

### 2.5 CCU 微码内部资源（hcomm 框架）

| 资源 | 说明 |
|------|------|
| **MS (Memory Space)** | CCU 内部 SRAM，每块 4096B，最多 8 个 |
| **Xn / GSA 寄存器** | 地址、长度、参数 |
| **CKE (Completed Kernel Event)** | AIV↔CCU、CCU 内部同步 |
| **Channel** | `CcuUrmaChannel`，绑定 RDMA QP |
| **CcuBuf** | 逻辑 buffer，映射到 MS |

数据传输相关微码指令（V1 节选）：

| 指令 | 语义 |
|------|------|
| `TransRmtMemToLocMem` | 远端 HBM → 本地 HBM |
| `TransLocMemToRmtMem` | 本地 HBM → 远端 HBM |
| `TransLocMemToLocMS` / `TransLocMSToLocMem` | 本地 HBM ↔ CCU MS |
| `TransRmtMemToLocMS` / `TransLocMSToRmtMem` | 远端 HBM ↔ CCU MS |

V2 统一为 `TransMem`，含 `dmaOpCode`（Write/Read/Send 等）。

---

## 3. 预置 CCU Kernel 与数据路径

PTO 在 `include/pto/comm/async/ccu/` 提供四个 1D-mesh gated kernel：

| Kernel 类 | 工厂 | 执行 rank | 数据路径（CcuRep 原语） |
|-----------|------|-----------|-------------------------|
| `CcuReduceMesh1D` | `MakeCcuReduceCreator()` | root | PreSync → `ReadNb`×(N-1) + `LocalCopyNb` → `LocalReduceNb` → `LocalCopyNb` → PostSync |
| `CcuGatherMesh1D` | `MakeCcuGatherCreator()` | root | `ReadNb` 拉各 rank input → root output 各 slice `LocalCopyNb` |
| `CcuScatterMesh1D` | `MakeCcuScatterCreator()` | root | root 各 slice `WriteNb` 到各 rank output + 本地 `LocalCopyNb` |
| `CcuBroadcastMesh1D` | `MakeCcuBroadcastCreator()` | root | root input `WriteNb` 到各 rank + 本地 `LocalCopyNb` |

公共框架（`ccu_mesh_common.hpp`）：

- `LoadPeerArgs` — 加载 GeneArgs 向量
- `NotifyBarrier` — channel 上 NotifyRecord/NotifyWait 对称 barrier（PreSync / PostSync）
- `PackPeerArgs` — Host 侧打包 peer 地址

**gate-only 模式**：无 CCU channel 时（`ownChannels_.empty()`），仅创建 gate/done event，Algorithm 在 gate 释放后直接 `RecordEvent(done)`，用于 ST 验证 CKE 通路。

---

## 4. 执行流程

### 4.1 Host 完整 Workflow

```
Init（每 rank 一次）
  ①  HcclCommInitRootInfo
  ②  HcclThreadAcquireWithStream(comm, COMM_ENGINE_CCU, stream, ...)
  ③  SetupChannelsForCcu — HcclRankGraphGetLinks + HcclChannelAcquire(UBC_CTP)
  ④  分配 input/output device buffer；CcuRep::GetTokenInfo 计算 token
  ⑤  MPI/HCCL AllGather 交换各 rank (inputVa, outputVa, token)

Per collective invocation
  ⑥  HcclCcuKernelRegister(creator, Ccu*KernelArg)  — 编译 Algorithm() → 微码
  ⑦  HcclCcuKernelRegisterFinish                  — 加载微码到 CCU
  ⑧  HcclCcuKernelLaunch(threadHandle, kHandle, Ccu*TaskArg)
  ⑨  GeneArgs → ccu::Publish → Host TryGet + rtGetDevResAddress → mmioAddr
  ⑩  Launch AIV kernel：TREDUCE<CCU>(..., CcuTriggerContext{mmio, mask, ...})
  ⑪  aclrtSynchronizeStream(aivStream) + aclrtSynchronizeStream(ccuStream)
```

详细接口表见源码 `include/pto/comm/async/ccu/ccu_mesh_common.hpp` 与 hcomm 侧 `hcomm/ccu/hccl_ccu_res.h`（`HcclCcuKernelRegister/Launch/RegisterFinish`）。

### 4.2 CCU 侧 Algorithm 状态机（以 Reduce 为例）

```
KernelLaunch 后 CCU 流进入 Algorithm():
  InitResource()           — 创建 Variable/Addr/Event；绑定 channel
  LoadArgs()               — 从 task 参数 Load 地址/token/length
  WaitEvent(gateEvent_)    — 阻塞，直到 AIV CkeTrigger
  PreSync()                — NotifyBarrier（各 rank input 就绪）
  if (rankId == root) DoReduce()
  PostSync()               — NotifyBarrier（结果可见）
  RecordEvent(doneEvent_)  — 通知 Host stream 可 sync
```

### 4.3 Device：CkeTrigger

```cpp
void CkeTrigger(uint64_t ckeSlotVA, uint32_t mask, __ubuf__ uint8_t *)
{
    volatile __gm__ uint64_t *p = (volatile __gm__ uint64_t *)ckeSlotVA;
    uint64_t payload = (uint64_t)mask | kCkeValidBit;  // bit63 = valid
    dcci → *p = payload → dcci → dsb(DSB_DDR) → pipe_barrier(PIPE_ALL);
}
```

- CCU 硬件读 slot 低 16 位 mask，触发后清空 slot。
- 必须显式 `dcci` + `dsb`（编译选项可能关闭标量自动 dcci）。

### 4.4 PTO CCU IMPL 路径

**Reduce / Gather**（`CcuStoreTriggerSelf`）：

1. `WaitAllEvents`（依赖的前序 event）
2. 若 `inputSource == AivStored`：`TSTORE(parallelGroup[selfIdx], tile)`
3. `CkeTrigger(ckeSlotVA, mask, ubScratch)`

**Scatter / Broadcast**（`CcuStoreTriggerRoot`）：

1. 若 root 且 `AivStored`：`TSTORE(srcGlobalData, tile)`
2. `CkeTrigger`

### 4.5 时序关系

```
Host          CCU 硬件                         AIV
  │              │                                │
  ├─ RegisterFinish → [微码 loaded]               │
  ├─ Launch ───────→ [LoadArgs, WaitEvent(gate)] │
  │              │   ←── gate_wait ──────────────│
  ├─ Launch AIV ─────────────────────────────────→│ CkeTrigger (~μs级)
  │              │←── gate released               │
  │              │   [PreSync → DoReduce → PostSync]
  │              │   RecordEvent(done)            │
  ├─ SyncStream ←──│                                │
```

> CCU_LAUNCH 总时间 ≈ **gate_wait**（CCU 空等 AIV）+ **actual_work**（gate 释放后 CCU 执行）。详见 `docs/treduce-perf-analysis/treduce-ccu-vs-aiv-perf-report.md`。

---

## 5. Channel 与寻址

### 5.1 SetupChannelsForCcu

对每个 peer rank：

1. `HcclRankGraphGetLinks(comm, netLayer, src, dst, &linkList, &listSize)`
2. 筛选 `linkProtocol == COMM_PROTOCOL_UBC_CTP`
3. `HcclChannelDescInit` + 填 `localEndpoint` / `remoteEndpoint`
4. `HcclChannelAcquire(comm, COMM_ENGINE_CCU, descs, count, channels)`

Channel 数 = `rankSize - 1`（不含 self）。

### 5.2 Token 与 RDMA 鉴权

```cpp
// 覆盖 input/output 跨度计算 token
uint64_t token = hcomm::CcuRep::GetTokenInfo(spanBase, spanEnd - spanBase);
```

各 rank 的 `(inputVa, outputVa, token)` 经 Host AllGather 写入 `Ccu*TaskArg::peer*`，微码 ReadNb/WriteNb 使用 `RemoteAddr{addr, token}`。

### 5.3 与 HCCL 窗口 / URMA 对称内存

| 路径 | 寻址 |
|------|------|
| SDMA | HCCL `windowsIn[rank] + offset` |
| URMA | 对称 MR `UrmaMemInfo.addr` |
| CCU | 用户分配 HBM + token；peer 地址 Host AllGather 注入 task |

---

## 6. 硬件与编程约束

| 约束项 | 说明 |
|--------|------|
| **HCCL 建域** | 必须；CCU channel 由 HCCL 分配 |
| **Kernel handle 一次性** | `HcclCcuKernelRegister` 的 handle 通常 **单次 Launch**；重复调用需新 signature（ST 用 seq 计数器） |
| **双 stream** | CCU stream（`HcclThreadAcquireWithStream`）+ AIV stream（trigger kernel）均需 sync |
| **CKE 解析时序** | Launch 后需等待 `GeneArgs` → `Publish`；Host 轮询 `TryGet`（ST 最多 200×10ms） |
| **rank 上限** | `kMaxReduceRanks = 16` |
| **gate-only** | 无 channel 时仅测 gate；需 `HCCL_PTO_GATE_DIE_ID` 指定 die |
| **AIV-only 平台** | 非 A5 / 无 CCU 时 `CollEngine::CCU` 分支不可编译或未链接 |
| **dcci 要求** | CKE MMIO 写必须 dcci+dsb |

---

## 7. 性能特征（概要）

> 定量数据见 `docs/treduce-perf-analysis/treduce-ccu-vs-aiv-perf-report.md`（A5, 2 rank, 2026-05）。

| 场景 | CCU | AIV |
|------|-----|-----|
| 小数据 Reduce | gate_wait 主导；端到端可能劣于 AIV | kernel 内 TLOAD+Reduce 极短 |
| 大数据 Reduce | CCU 微码分块 + 硬件 RDMA；actual_work 随 payload 增长 | AIV 多轮 TLOAD/规约/STORE |
| 触发开销 | AIV 仅 CKE 写（~μs） | AIV 承担全部通信计算 |

CCU 优势区间：**payload 较大、rank 间需 RDMA + MS 规约融合**；小消息需评估 gate_wait 与 Host 注册开销。

---

## 8. 关键设计决策

### 8.1 为何不用 AsyncSession

CCU 是 **Host 预注册微码 + Launch 参数注入** 模型，与运行时填 SQ 的 DMA 路径正交；PTO 用 `CcuTriggerContext` 仅传递 AIV 触发所需 MMIO 信息。

### 8.2 Host AllGather 替代运行时地址交换

`PackPeerArgs` 在 Launch 前注入全部 peer VA/token，CCU `PreSync` 只做 readiness barrier（确认各 rank input 已由 AIV/Host 写好），**不做**运行时地址 discovery。

### 8.3 Gate 解耦 AIV 与 CCU

CCU Launch 后可立即进入 `WaitEvent(gate)`；AIV 在独立 stream 上完成计算后写 CKE。允许 **CCU 先启动、AIV 后触发**，支持通算重叠（需正确 stream 编排）。

### 8.4 Process-local Gate Registry

`ccu_gate_registry.hpp` 为进程内 `unordered_map`（非跨进程 IPC）；ST 中 Register/Launch/Trigger 同进程，`TryGet` 可工作。生产环境应由 HCCL/hcomm 框架提供等价的 gate 发现机制。

---

## 9. 源文件索引

| 文件 | 作用 |
|------|------|
| `include/pto/comm/async/ccu/ccu_types.hpp` | `CcuGateDescriptor`、常量 |
| `include/pto/comm/async/ccu/ccu_gate_registry.hpp` | Host `Publish` / `TryGet` |
| `include/pto/comm/async/ccu/ccu_mesh_common.hpp` | 1D-mesh 公共 Load/Sync/Pack |
| `include/pto/comm/async/ccu/ccu_reduce_kernel.hpp` | Reduce kernel + Kernel/Task arg |
| `include/pto/comm/async/ccu/ccu_gather_kernel.hpp` | Gather kernel |
| `include/pto/comm/async/ccu/ccu_scatter_kernel.hpp` | Scatter kernel |
| `include/pto/comm/async/ccu/ccu_broadcast_kernel.hpp` | Broadcast kernel |
| `include/pto/comm/async_common/ccu_trigger.hpp` | `CkeTrigger`、`CcuStoreTriggerSelf/Root` |
| `include/pto/comm/comm_types.hpp` | `CollEngine`、`CcuTriggerContext`、`CcuInputSource` |
| `include/pto/comm/pto_comm_inst.hpp` | `TREDUCE/TGATHER/TSCATTER/TBROADCAST` CCU 分派 |
| `include/pto/comm/a5/TReduce.hpp` 等 | A5 CCU IMPL |
| `tests/npu/a5/comm/st/testcase/treduce_ccu/main.cc` | 端到端 ST（完整 Host 流程） |
| `tests/npu/a5/comm/st/testcase/tgather_ccu/` 等 | 其它 collective ST |
| `tests/npu/a5/comm/st/testcase/ccu_test_main.hpp` | ST 公共辅助 |

hcomm 侧（非 pto-isa 仓，运行时依赖）：

| 路径 | 作用 |
|------|------|
| `hcomm/ccu/ccu_kernel.h` | `CcuKernel` 基类、`Algorithm`/`GeneArgs` |
| `hcomm/ccu/hccl_ccu_res.h` | `HcclCcuKernelRegister/Launch/RegisterFinish` |
| `hcomm/ccu/ccu_rep_*.cc` | `ReadNb`/`WriteNb` → 微码翻译 |

---

## 10. 相关文档索引

| 文档 / 代码 | 内容 |
|------|------|
| [[comm-async-sdma]] | 点对点 SDMA 后端 |
| [[comm-async-urma]] | 点对点 URMA 后端 |
| `include/pto/comm/async/ccu/ccu_mesh_common.hpp` + `hcomm/ccu/hccl_ccu_res.h` | CCU Host 流程与接口（原 host_side_setup §4） |
| `include/pto/comm/comm_types.hpp` | CCU 与 SDMA/URMA 引擎对比、微码 ISA（原 engine_sqe_comparison §4） |
| `code/pto-isa-main/docs/isa/comm/TREDUCE_zh.md` 等 | 指令级 ISA 说明 |
| `docs/treduce-perf-analysis/treduce-ccu-vs-aiv-perf-report.md` | CCU vs AIV 性能实测 |

---

## 11. 引擎选型指南

| 场景 | 建议 |
|------|------|
| 点对点 PUT/GET、自定义通信 pattern | **SDMA** 或 **URMA** |
| 标准 Reduce/Gather/Scatter/Broadcast、payload 较大 | **CollEngine::CCU** |
| 小消息 Reduce、无 CCU 或注册开销不可接受 | **CollEngine::AIV** |
| 需要与 AIV 计算精细交织的小 tile | **AIV** 路径更灵活 |
| MoE / 通算融合中的集合段 | 视 payload 与 HCCL 集成选 CCU 或 AIV |
| 无 HCCL 建域 | CCU **不可用**（考虑 URMA 点对点拼集合） |

---

## 12. 典型用法 sketch

```cpp
// ===== Host（简化，见 treduce_ccu/main.cc）=====
HcclThreadAcquireWithStream(comm, COMM_ENGINE_CCU, ccuStream, 1, &threadHandle);
SetupChannelsForCcu(comm, rankId, nRanks, channels);
// AllGather peer (inputVa, outputVa, token) ...

CcuReduceKernelArg karg{rankId, nRanks, rootId, HCCL_DATA_TYPE_FP32, HCCL_REDUCE_SUM, payloadBytes};
karg.channels = channels;
HcclCcuKernelRegister(comm, &kHandle, &MakeCcuReduceCreator(), &karg);
HcclCcuKernelRegisterFinish(comm);

CcuReduceTaskArg targ{inputVa, outputVa, length, token};
targ.SetPeerAddrs(nRanks, allInputVa, allOutputVa, allToken);
HcclCcuKernelLaunch(comm, threadHandle, kHandle, &targ);

CcuGateDescriptor gate{};
while (!ccu::TryGet(rankId, gate)) { /* retry */ }
// rtGetDevResAddress → gate.mmioAddr

CcuTriggerContext ctx{gate.mmioAddr, gate.mask, rankId, CcuInputSource::AivStored};

// ===== Device AIV kernel =====
TREDUCE<CollEngine::CCU>(parallelGroup, dstGlobal, accTile, recvTile, ReduceOp::SUM, ctx);

// ===== Host sync =====
aclrtSynchronizeStream(aivStream);
aclrtSynchronizeStream(ccuStream);
```

---

## 13. 已知限制与待补充

| 项 | 现状 |
|----|------|
| 拓扑 | 仅 1D-mesh；无 ring/tree CCU kernel 于 PTO 仓 |
| Gate registry | 进程内 map；分布式生产路径待框架统一 |
| Cost model | 无独立文稿；§7 引用 perf report |
| Kernel 复用 | handle 一次性；高频调用需缓存策略或 batch |
| 文档-代码 | 以 `code/pto-isa-main/include/pto/comm/async/ccu/` 为准 |
