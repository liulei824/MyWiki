# PTO 异步通信 · SDMA 后端

- **来源**: `code/pto-isa-main` 源码 + 工作区 `docs/costModel/`、`docs/sdma_*` 等分析文档整合
- **整理日期**: 2026-06-29（路径已对齐当前仓库结构）
- **类型**: 自写综合笔记（完整知识正文）

> 覆盖：架构模型、核心数据结构、执行流程、硬件约束、Cost Model、多 Rank 调度、已知问题与修复。
> 关联：[[comm-isa]]（通信 ISA 总览）、[[comm-async-urma]]、[[comm-async-ccu]]、[[pto-overview]]

---

## 1. 架构概述

### 1.1 三层执行实体

```
┌──────────────────────────────────────────────────────────────┐
│ AI Core (标量/向量单元)                                       │
│   BuildAsyncSession、SQE 填写、Wait 轮询等软件逻辑            │
├──────────────────────────────────────────────────────────────┤
│ MTE 管道 (MTE2: GM→UB, MTE3: UB→GM)                         │
│   SetValue / GetValue 的 UB staging 传输                     │
├──────────────────────────────────────────────────────────────┤
│ SDMA 硬件引擎 (独立于 AI Core)                                │
│   从 SQ 中消费 SQE，完成 GM→GM DMA 传输                      │
└──────────────────────────────────────────────────────────────┘
```

- AI Core 与 SDMA 引擎可并行；并行窗口仅在 Wait 的 poll-spin 阶段（doorbell 延迟设计）。
- MTE 管道与标量单元通过 `pipe_barrier` / `set_flag` / `wait_flag` 同步，形成串行依赖。

### 1.2 SDMA 指令语义

| 指令 | 语义 | 数据流 |
|------|------|--------|
| `TPUT_ASYNC` | 异步远程写 | 本地 GM → SDMA → 远端 GM |
| `TGET_ASYNC` | 异步远程读 | 远端 GM → SDMA → 本地 GM |

核心特点：
- **非阻塞**：立即返回 `AsyncEvent`，后台完成搬运。
- **Quiet 语义**：多次异步调用后一次 `event.Wait()` 等待全部完成。
- **仅支持扁平连续 1D tensor**。
- **Doorbell 延迟提交**：数据 SQE 在发起阶段仅写入 SQ 内存，不敲门铃；doorbell 统一在 Wait 阶段与 flag SQE 一起提交。
- **PUT 与 GET 底层完全相同**：`__sdma_put_async` 和 `__sdma_get_async` 都调用 `SdmaWrite → SdmaPostSendAsyncWithCtx`，opcode 均为 0，方向由地址决定。

### 1.3 A5 架构差异

- `TPUT_ASYNC`：A5 回退到 **MTE 同步传输**（非 SDMA PUT），返回 `handle=0`，Wait 立即返回。
- `TGET_ASYNC`：仍可使用 SDMA 路径。
- SQE 布局、doorbell 寄存器偏移、`kernel_credit` 常量均与 A2/A3 不同。

---

## 2. 核心常量与数据结构

### 2.1 常量速查

| 符号 | 值 | 说明 |
|------|------|------|
| `kDefaultSdmaBlockBytes` | 1,048,576 (1 MB) | 每个数据 SQE 的默认传输块大小 |
| `kSdmaMaxChannel` | 48 | 最大 SDMA 通道数 |
| `kSqDepth` | 2048 | 每个 SQ 的环形缓冲区深度 |
| `kSdmaFlagLength` | 128 | Event workspace 中每通道组 flag 区域长度 (字节) |
| `kSdmaEventRecordBytes` | 16 | `SdmaEventRecord` 结构体大小 |
| `kMinSdmaTransferBytes` | 64 | SDMA 最小传输粒度 / EventRecord 间距 |
| `kSdmaEventSlotCount` | 8 | Event 插槽数 (128/16) |
| `kUbAlignSize` | 256 | 推荐 scratch tile 大小 |
| `K_CREDIT_TIME_DEFAULT` | 240 (A2/A3) / 254 (A5) | SQE 中 `kernel_credit` 字段 |
| `RT_STARS_SQE_TYPE_SDMA` | 11 | SQE 类型标识 |
| `kSdmaMaxChan` (Host) | 48 | Host 侧最大通道数 |
| `kSdmaWorkspaceBytes` (Host) | 16,384 (16 KB) | Host 侧 Device workspace 分配大小 |
| `kMaxPollTimes` | 1,000,000 | Wait 轮询上限 |

### 2.2 核心结构体

```cpp
// 用户侧配置
struct SdmaBaseConfig {
    uint64_t block_bytes;         // 每 SQE 传输块大小 (默认 1MB)
    uint64_t comm_block_offset;   // 本核数据偏移
    uint32_t queue_num;           // 每核使用的 SQ 队列数 (默认 1)
};

// Device 侧执行上下文
struct SdmaExecContext {
    __gm__ uint8_t *contextGm;   // workspace 指针
    TmpBuffer tmpBuf;             // UB scratch {addr, size}
    uint32_t syncId;              // MTE 管道同步 ID (0-7)
    uint32_t channelGroupIdx;     // SDMA 通道组索引
    SdmaBaseConfig baseConfig;
};
```

**SdmaEventRecord** (16 字节，但按 64 字节间距排列)：

| 偏移 | 类型 | 字段 | 说明 |
|------|------|------|------|
| 0 | uint32_t | flag | 完成标志 (非零=完成) |
| 4 | uint32_t | sq_tail | 完成时的 tail 值 |
| 8 | uint64_t | channel_info | 指向 `BatchWriteChannelInfo` 的指针 |

**BatchWriteChannelInfo** (64 字节)：

| 字段 | 说明 |
|------|------|
| sq_head + sq_tail | 8 字节对齐打包读写 |
| sq_base | SQ 缓冲区基址 |
| sq_reg_base | SQ 寄存器基址 (doorbell 地址) |
| sq_depth | SQ 深度 (2048) |
| sq_id / cq_id / logic_cq_id | 通道标识 |
| stream_id / dev_id | 设备标识 |

**BatchWriteItem (SQE)** — 64 字节，A2/A3 与 A5 布局不同：

| 平台 | 关键字段差异 |
|------|-------------|
| A2/A3 | `kernel_credit=240`, `qos=6`, `partid=0`, `linkType=255` |
| A5 | `kernelCredit=254`, `wrCqe=1`, `numBlocks=0`, `lengthMove` |

### 2.3 Device Workspace 内存布局

```
contextGm (workspace 基地址)
├── [+0]     BatchWriteFlagInfo (64B)
│            flag | totalQueueNum | reserved[56]
├── [+64]    BatchWriteChannelInfo[48] (48 × 64B = 3KB)
│            每个 channel: sq_head|sq_tail|sq_base|sq_reg_base|...
├── [+3136]  Event Workspace
│  ├── send_workspace (128B)
│  │   └── 每队列 64B sendBuf (UB 组装的 record 暂存)
│  └── recv_workspace[N] (每核 queue_num × 128B)
│      └── SdmaEventRecord[queue_num] (64B 间距)
```

---

## 3. 执行流程

### 3.1 完整 Workflow

```
Host: SdmaWorkspaceManager::Init()
  → CreateStarsStreams(48)
  → MallocWorkspace(16KB)
  → AICPU 填充 workspace (SQ base, reg base, depth, ...)
      ↓ workspace 指针传入 kernel
Device:
  ① BuildAsyncSession          建立会话 (纯标量)
  ② TPUT_ASYNC / TGET_ASYNC    填写数据 SQE (不敲门铃)
  ③ (可继续计算或再次异步调用)
  ④ event.Wait(session)         追加 Flag SQE → dcci + dsb → 敲门铃
                                → 轮询完成
```

### 3.2 发起传输：SdmaPostSendAsyncWithCtx

```
1. BuildTransferConfig    → iter_num = ⌈messageLen / block_bytes⌉
2. 越界检查               → sqePerQueue ≤ kSqDepth
3. 定位 BatchWriteChannelInfo
4. InitSqTailArray        → Q 次 GM 读 (MTE2)
5. SubmitDataTransferSqes → iter_num 次 SQE 填写 (round-robin 分配到 Q 个队列)
6. ★ 不敲 doorbell        → doorbell 延迟到 Wait
7. UpdateSqTailState      → uint64_t 打包写 sq_head + sq_tail
8. return contextGm 作为 event handle
```

### 3.3 等待完成：SdmaWaitEvent

```
Phase A: PrepareEventCheck
  ├── InitSqTailArray
  ├── SubmitFlagTransferSqes    每个 queue:
  │     ① uint64_t 原子清零 record (flag + sq_tail)
  │     ② UB 组装完整 SdmaEventRecord
  │     ③ MTE3 拷贝 64B → sendBuf
  │     ④ AddOneMemcpySqe (Flag SQE: sendBuf → record)
  ├── FlushCacheAndRingDoorbell 每个 queue:
  │     dcci(sq_base) → pipe_barrier → dsb(DDR) → ★ 敲门铃
  └── UpdateSqTailState

Phase B: 轮询等待
  每个 queue:
    dcci(record, SINGLE_CACHE_LINE)
    反复 GetValue(record->flag) 直到非零 (最多 1,000,000 次)

Phase C: HandleCompletedEventRecord
  每个 queue:
    先读 sq_tail + channel_info → uint64_t 清零 record
    → uint64_t 打包写 channelInfo (sq_head = sq_tail = completedTail)
```

### 3.4 Channel 分配

```
48 个 Channel 按 queue_num 分组：
  channelGroupIdx = block_idx (默认)
  该 block 使用 channel[channelGroupIdx * queue_num .. + queue_num - 1]

约束：channelGroupIdx < 48 / queue_num
  queue_num=1 → 最多 48 核并行
  queue_num=2 → 最多 24 核并行
  queue_num=4 → 最多 12 核并行
```

### 3.5 多队列条带化

当 `queue_num > 1` 时，数据块 round-robin 分配：
```
iter 0 → queue 0
iter 1 → queue 1
iter 2 → queue 0  (若 queue_num=2)
...
```
多个 SDMA 通道并行传输，理论带宽提升为 `min(Q, N) × 单 channel 带宽`。

---

## 4. 硬件约束总表

| 约束项 | 说明 |
|--------|------|
| **MTE3 最小写入 8 字节** | 写 4 字节会清零相邻 4 字节；必须用 uint64_t 打包写或 UB 整体拷贝 |
| **SDMA 最小传输 64 字节** | Flag SQE 传输 64B；EventRecord 需按 64B 间距排列 |
| **L2 Cache 一致性** | SDMA 写 HBM，AI Core 读前必须 `dcci` 失效对应 cache line |
| **Doorbell 前置条件** | 敲门铃前必须 `dcci + pipe_barrier + dsb(DSB_DDR)` 保证 SQE 落盘 |
| **Tensor 布局** | 仅扁平连续逻辑一维 |
| **SQ 深度限制** | 单队列 SQE 数 ≤ 2048 (含 flag SQE) |
| **syncId 范围** | 0-7，与其他 MTE 屏障共享 |
| **轮询上限** | Wait 最多 1,000,000 次 |
| **A5 PUT 限制** | `TPUT_ASYNC` 回退为 MTE 同步，不走 SDMA |
| **Doorbell 地址** | A5: `sq_reg_base`；A2/A3: `sq_reg_base + 8` |

---

## 5. Cost Model

### 5.1 时间分解

```
T_kernel = T_build + T_post + T_wait
```

其中 `T_wait` 内含 SDMA 硬件传输时间，与 poll spin 重叠。

### 5.2 T_post（发起传输）

```
T_post ≈ Q × (2 × t_gv + t_sv) + N × t_sqe
         \_______  ___________/   \___ ____/
                \/                    \/
          队列状态读写            SQE 批量填写

Q = queue_num
N = iter_num = ⌈messageLen / block_bytes⌉
```

- **SQE 填写是主导项**：大数据时 `N × t_sqe` 占主导。
- **无 doorbell**：SDMA 引擎在 T_post 期间完全空闲。

### 5.3 T_wait（等待完成）

```
T_wait = T_prepare + T_poll + T_handle

T_prepare ≈ Q × (3×t_gv + 3×t_sv + t_mte3_64 + t_sqe + t_dcci + t_dsb + t_doorbell)
T_poll    = Q × P × (t_dcci + t_gv)     // P = 轮询次数，与 SDMA 传输时间相关
T_handle  = Q × (2×t_gv + 2×t_sv)
```

### 5.4 AI Core 与 SDMA 并行时序

```
Device:  ├── T_prepare ──┤──────── T_poll ────────┤── T_handle ──┤
                         ⚡doorbell
SDMA:                    ├─ fetch ─┤──── T_transfer ────┤─ flag ─┤

T_poll 与 T_transfer 的 wallclock 完全重叠 (spin 等待)
```

### 5.5 最终公式

```
T_kernel(messageLen, Q, B) =
  C_build
+ Q × (2×t_gv + t_sv) + N × t_sqe                                    [T_post]
+ Q × (3×t_gv + 3×t_sv + t_mte3_64 + t_sqe + t_dcci + t_dsb + t_db) [T_prepare]
+ T_fetch + messageLen / (min(Q, N) × BW_sdma) + T_flag_write         [T_sdma]
+ Q × (2×t_gv + 2×t_sv)                                              [T_handle]
```

### 5.6 参数敏感性

| 参数 | 影响 |
|------|------|
| `messageLen ↑` | N 增大 → T_post 线性增长；T_sdma 线性增长；大数据时 T_sdma 主导 |
| `queue_num ↑` | 带宽提升但 T_prepare / T_handle 线性增加；收益拐点取决于单 channel 是否打满 |
| `block_bytes ↑` | N 减小 → SQE 开销降低；T_sdma 不变；默认 1MB 已合理 |

### 5.7 批量模型

```
多次 TPUT_ASYNC + 一次 Wait:
  T_batch = T_build + Σ(T_post_k) + T_wait(总)
  
  优势：一次 doorbell + 一组 flag → 节省 (K-1) × T_prepare
```

### 5.8 待标定原子操作常数

| 符号 | 含义 | 预期量级 |
|------|------|---------|
| `t_gv` | GetValue (MTE2 GM→UB + barrier + 标量读) | 几十~上百 cycle |
| `t_sv` | SetValue (UB写 + barrier + MTE3 UB→GM + flag sync) | 几十~上百 cycle |
| `t_sqe` | AddOneMemcpySqe (~15 标量写 GM + barrier) | 几十~上百 cycle |
| `t_dcci` | dcci (cache invalidate) | 几十 cycle |
| `t_dsb` | dsb(DSB_DDR) | 几十 cycle |
| `t_mte3_64` | MTE3 拷贝 64B | 几十 cycle |
| `BW_sdma` | 单 SDMA channel 带宽 | GB/s 级 |

---

## 6. 多 Rank 调度

### 6.1 通信窗口

每个 Rank 通过 HCCL 建立通信域后，获得 RDMA 可访问的共享内存窗口：
```
HcclDeviceContext:
  windowsIn[64]   各 Rank 窗口基地址
  rankId / rankNum / winSize

远程地址翻译:
  offset = localPtr - windowsIn[myRank]
  remotePtr = windowsIn[targetRank] + offset
```

### 6.2 Direct AllGather

每个 Rank 启动 N 个 AI Core，每核负责向一个目标 Rank TPUT_ASYNC：
- `block_idx == myRank` 的核做本地 MTE 拷贝
- 其余核做远程 SDMA 写入
- 一次 Kernel Launch 完成全部通信
- 适用：小数据、少 Rank、全连接带宽充足

### 6.3 Ring AllGather

N-1 轮，每轮每 Rank 向下一个 Rank 推送一个 chunk：
- 轮内：所有 Rank 并行发送
- 轮间：Host Barrier 串行同步（数据依赖）
- 单核执行
- 适用：大数据、多 Rank、带宽受限

### 6.4 两种模式对比

| 维度 | Direct | Ring |
|------|--------|------|
| Kernel 次数 | 1 | N-1 |
| AI Core 数/Rank | N | 1 |
| 通信轮数 | 1 | N-1 |
| 同步开销 | 1 次 | N-1 次 |
| SDMA 通道占用 | N 组 | 1 组 |

---

## 7. 关键设计决策与修复历史

### 7.1 MTE3 8 字节写入粒度问题（根因）

在 Ring AllGather 多轮跨 kernel 通信中发现：MTE3 最小写入粒度为 8 字节，使用 `SetValue<uint32_t>` 写 4 字节会清零相邻 4 字节。

**影响范围与修复**：

| 场景 | 受影响字段 | 修复方案 |
|------|-----------|---------|
| 清零 `record->flag` | 连带清零 `sq_tail` | `SetValue<uint64_t>` 原子清零 |
| 写 `record->sq_tail` | 连带清零 `flag` | UB 组装完整 record 后整体 64B MTE3 拷贝 |
| 写 `channelInfo->sq_tail` | 连带清零 `sq_head` | 读 sq_head → 打包 uint64_t 写 |
| `HandleCompletedEventRecord` | 先清 flag 后读 sq_tail 读到 0 | 调整为先读后写 |

### 7.2 EventRecord 间距问题

`SdmaEventRecord` 仅 16 字节，但 Flag SQE 传输 64 字节。`queue_num ≥ 2` 时按 16 字节排列会重叠。**修复**：间距改为 64 字节。

### 7.3 Doorbell 延迟设计

原实现在 `TPUT_ASYNC` 和 `Wait` 各敲一次 doorbell，存在时序窗口。**修复**：doorbell 统一延迟到 Wait 的 `FlushCacheAndRingDoorbell`，数据 SQE + flag SQE 一次性提交。

### 7.4 Cache 一致性

SDMA 直接写 HBM，AI Core MTE2 读可能命中 L2 旧值。**修复**：轮询前 `dcci(record, SINGLE_CACHE_LINE)` + `__asm__ __volatile__("")` 防重排；敲门铃前 `dcci(sq_base) + pipe_barrier + dsb(DSB_DDR)` 保证 SQE 落盘。

---

## 8. 源文件索引

> 路径以当前仓库结构为准（2026-06-29 校正：SDMA 实现已从 `include/pto/npu/comm/...` 迁至 `include/pto/comm/async/sdma/`；`async_types`/`async_event_impl` 移入 `async_common/`；`TPut/TGetAsync` 按架构拆到 `a2a3/`、`a5/`，公共逻辑在 `async_common/*CommonDetail.hpp`）。

| 文件 | 作用 |
|------|------|
| `include/pto/comm/async/sdma/sdma_types.hpp` | BatchWriteItem, BatchWriteChannelInfo, SdmaEventRecord 等硬件结构 |
| `include/pto/comm/async/sdma/sdma_async_intrin.hpp` | SDMA 底层实现核心 (SQE 填写/Flag/Doorbell/Poll) |
| `include/pto/comm/async/sdma/sdma_workspace_manager.hpp` | Host 侧初始化 (STARS Streams, Workspace) |
| `include/pto/comm/async/sdma/sdma_cmo_intrin.hpp` | CMO（cache 维护）相关 SQE |
| `include/pto/comm/async_common/async_types.hpp` | AsyncSession, SdmaExecContext, SdmaBaseConfig |
| `include/pto/comm/async_common/async_event_impl.hpp` | BuildAsyncSession, AsyncEvent::Wait/Test |
| `include/pto/comm/async_common/TPutAsyncCommonDetail.hpp` | TPUT_ASYNC 公共分发逻辑 |
| `include/pto/comm/async_common/TGetAsyncCommonDetail.hpp` | TGET_ASYNC 公共分发逻辑 |
| `include/pto/comm/a2a3/async/TPutAsync.hpp` / `a5/async/TPutAsync.hpp` | 各架构 TPUT_ASYNC 实现 (SDMA/MTE/URMA 分发) |
| `include/pto/comm/a2a3/async/TGetAsync.hpp` / `a5/async/TGetAsync.hpp` | 各架构 TGET_ASYNC 实现 |
| `include/pto/comm/pto_comm_inst.hpp` | 公开 API 入口 |

---

## 9. 相关文档索引

| 文档 | 内容 |
|------|------|
| `docs/costModel/sdma_cost_model_v1.md` | 执行时序分析与量化公式 |
| `docs/costModel/sdma_channel_queue_sqe.md` | Channel/Queue/SQE 可视化 (10MB 示例) |
| `docs/costModel/sdma_async_workflow.md` | 端到端 Workflow 与代码级分析 |
| `docs/costModel/sdma_multi_rank_scheduling.md` | 多 Rank 通信调度 (Direct/Ring) |
| `docs/sdma_async_intrin_changes.md` | 8 大修复的详细说明 |
| `docs/pto-isa_vs_shmem_sdma_async_analysis.md` | PTO-ISA vs shmem 实现对比 |
| `docs/sdma_cmo_sqe_performance_investigation.md` | SQE 字段级性能调研 (跨 shmem/hcomm/driver) |
| `docs/tput_tget_async_config_guide.md` | 配置 FAQ 与使用指南 |

---

## 10. 已知文档-代码不一致

| 文档描述 | 代码实际 | 以哪个为准 |
|----------|---------|-----------|
| `pto-isa_vs_shmem` 称默认 block = 32KB | `async_types.hpp` 定义 `kDefaultSdmaBlockBytes = 1MB` | **代码 (1MB)** |
| 部分文档暗示 `queue_num > 1` 时仅 queue 0 跟踪事件 | `SdmaWaitEvent` 对所有 `queueId < queueNum` 都提交 flag 并轮询 | **代码 (所有 queue)** |

---

## 11. 参数选择指南速查

### queue_num

| queue_num | 并行度 | 最大 block 数 | 适用场景 |
|-----------|--------|-------------|---------|
| 1 | 串行 | 48 | 小数据 (<1MB)、核数多 |
| 2 | 2 路并行 | 24 | 中等数据 (1-10MB) |
| 4 | 4 路并行 | 12 | 大数据 (>10MB)、核数少 |

### block_bytes

| block_bytes | 10MB 的 SQE 数 | SQE 开销 | 适用场景 |
|-------------|---------------|---------|---------|
| 256 KB | 40 | 高 | 小块精细控制 |
| 1 MB (默认) | 10 | 低 | 大多数场景 |
| 2 MB | 5 | 很低 | 超大传输 |

### SQE 容量

```
sqePerQueue = ⌈iter_num / queue_num⌉ + 1  ≤  kSqDepth (2048)
```
