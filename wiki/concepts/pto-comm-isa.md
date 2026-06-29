# pto-comm-isa

- **领域**: PTO-ISA 通信扩展
- **首次记录**: 2026-06-29
- **来源数**: 2

## 定义

PTO 通信 ISA 是 [[pto-isa]] 计算 tile 指令的**通信扩展**，面向 **NPU 之间**的数据传输、信号同步与集合通信，延续 tile 级抽象与跨平台设计，可驱动多种数据搬移硬件引擎，用于构建计算与通信深度融合的 kernel。公共 API：`include/pto/comm/pto_comm_inst.hpp`（按宏分发后端）。

## 核心内容

### 四类指令

| 类别 | 指令 | 说明 |
|------|------|------|
| 点对点（同步） | `TPUT`、`TGET` | 经 UB 暂存的远程写/读（GM→UB→GM），支持单缓冲/ping-pong |
| 点对点（异步） | `TPUT_ASYNC`、`TGET_ASYNC` | 经 [[sdma|SDMA]]/[[urma|URMA]] 的 GM-to-GM DMA，返回 `AsyncEvent` 供 Wait/Test |
| 信号同步 | `TNOTIFY`、`TWAIT`、`TTEST` | 基于标志的跨 NPU 同步；信号为 `int32_t` 标量或二维网格 |
| 集合通信 | `TGATHER`、`TSCATTER`、`TBROADCAST`、`TREDUCE` | 基于 `ParallelGroup` 的多 rank 操作，root 发起；可走 [[ccu|CCU]] 硬件加速 |

> 工作区术语对齐：**同步通信指令** = 非 `*_ASYNC` 原语；**异步通信指令** = `TPUT_ASYNC`/`TGET_ASYNC`（经 DMA 引擎 + `AsyncSession`，返回 `AsyncEvent`，可与计算重叠）。

### 异步路径：AsyncSession / AsyncEvent

`AsyncSession` 引擎无关，构建一次传给所有异步调用；`AsyncEvent{handle, engine}` 提供 `Wait()`/`Test()`。`DmaEngine::SDMA`（A950 上仅 TGET）/`DmaEngine::URMA`（仅 A950，CANN≥9.1.0）。类型在 `async_common/async_types.hpp`，实现在 `async_event_impl.hpp`。后端能力差异见 [[pto-backend]]。

### 三个后端实现（详见各概念页）

- **[[sdma]]**：填 64B SQE，doorbell 延迟到 Wait，Flag SQE + `SdmaEventRecord` 轮询；默认 block 1MB、≤48 通道。
- **[[urma]]**：填 WQE，PostSend 即敲 doorbell，轮询 CQ owner 位；HCCP V2 Jetty + 对称 MR，无 UB scratch。
- **[[ccu]]**：集合通信硬件加速，不走 `AsyncSession`；Host 预注册微码 + AIV 写 CKE gate 触发，1D-mesh，rank≤16。

### 信号与集合

- `TNOTIFY`（`Set`/`AtomicAdd`）、`TWAIT`/`TTEST`（`EQ/NE/GT/GE/LT/LE`）。
- `ParallelGroup` 封装各 rank 的 GlobalTensor 数组（`tensors`/`nranks`/`rootIdx`），集合操作支持 2D 分块滑动 + ping-pong。

### 后端目录

`include/pto/comm/`：`pto_comm_inst.hpp`（API）、`pto_comm_instr_impl.hpp`（分发）、`comm_types.hpp`（类型）、`a2a3/`、`a5/`、`async_common/`、`async/{sdma,urma,ccu}/`。

## 相关

- 实体：[[pto-isa]]、[[ascend-950]]
- 概念：[[pto-instruction-set]]、[[pto-backend]]、[[pto-tile]]、[[sdma]]、[[urma]]、[[ccu]]、[[unified-bus]]
- 资料：[[source-pto-comm]]、[[source-pto-isa]]
