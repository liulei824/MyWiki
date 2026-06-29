# PTO 通信 ISA（NPU 间数据传输 / 信号 / 集合通信）

- **来源**: `code/pto-isa-main` — `docs/isa/comm/README_zh.md`、`include/pto/comm/README_zh.md`、`include/pto/comm/pto_comm_inst.hpp`、`comm_types.hpp`
- **整理日期**: 2026-06-29
- **类型**: 自写综合笔记（基于官方仓库文档）

## 定位

PTO 通信 ISA 是计算 Tile 指令的**通信扩展**，面向 **NPU 之间**的数据传输、信号同步与集合通信，延续与计算指令一致的 tile 级抽象和跨平台设计，可驱动昇腾上多种数据搬移硬件引擎，用于构建**计算与通信深度融合**的 kernel。

- 公共 API 头：`include/pto/comm/pto_comm_inst.hpp`（上层只需 include 这一个，按宏分发到后端）
- 类型定义：`include/pto/comm/comm_types.hpp`
- 逐指令参考：`docs/isa/comm/<指令>_zh.md`

## 四类指令

| 类别 | 指令 | 说明 |
|------|------|------|
| 点对点（同步） | `TPUT`、`TGET` | 经 UB 暂存 Tile 的远程写/读（GM→UB→GM）。支持单缓冲与 ping-pong 双缓冲 |
| 点对点（异步） | `TPUT_ASYNC`、`TGET_ASYNC` | 经 SDMA/URMA 引擎的 GM-to-GM DMA，返回 `AsyncEvent` 供后续 Wait/Test |
| 信号同步 | `TNOTIFY`、`TWAIT`、`TTEST` | 基于标志的跨 NPU 同步；信号为 `int32_t` 标量或二维网格 |
| 集合通信 | `TGATHER`、`TSCATTER`、`TBROADCAST`、`TREDUCE` | 基于 `ParallelGroup` 的多 rank 操作，root 发起，支持 2D 分块滑动 + ping-pong |

> 术语对齐（工作区约定）：**同步通信指令** = 非 `*_ASYNC` 的原语（`TPUT`/`TGET`/`TNOTIFY`/`TWAIT`/`TTEST` 及集合）；**异步通信指令** = `TPUT_ASYNC`/`TGET_ASYNC`（经 DMA 引擎 + `AsyncSession`，返回 `AsyncEvent`，可与计算重叠）。

## 一、点对点同步：TPUT / TGET

- `TPUT`：远程**写**——本地 GM → UB → 远端 GM
- `TGET`：远程**读**——远端 GM → UB → 本地 GM
- 经 UB 暂存，故占用向量 buffer；支持单缓冲 / ping-pong 双缓冲（双缓冲重叠搬运与计算）

## 二、点对点异步：TPUT_ASYNC / TGET_ASYNC

GM-to-GM DMA，**不经 UB**，与计算重叠后再同步。

### DmaEngine 选择

| 值 | 说明 |
|----|------|
| `DmaEngine::SDMA` | SDMA 引擎；一维传输（**Ascend950 上仅支持 TGET**） |
| `DmaEngine::URMA` | URMA 引擎；一维传输；**仅 Ascend950 / NPU_ARCH 3510，要求 CANN ≥ 9.1.0** |

后端能力（见 [[backend-and-arch]]）：A2/A3 仅 SDMA；A5 的 `TPUT_ASYNC` = SDMA + MTE 回退 + URMA，`TGET_ASYNC` = SDMA + URMA。

### AsyncEvent / AsyncSession

```cpp
struct AsyncEvent {
    uint64_t handle;
    DmaEngine engine;
    bool valid() const;                            // handle != 0
    bool Wait(const AsyncSession &session) const;  // 阻塞至完成
    bool Test(const AsyncSession &session) const;  // 非阻塞检测
};
```

`AsyncSession` 是**引擎无关**会话，构建一次后传给所有异步调用：

```cpp
comm::AsyncSession session;
comm::BuildAsyncSession<comm::DmaEngine::SDMA>(scratchTile, workspace, session);
// ...
comm::AsyncEvent ev = comm::TPUT_ASYNC(...);
ev.Wait(session);
```

类型定义：`include/pto/comm/async_common/async_types.hpp`；`Wait/Test`、`BuildAsyncSession` 实现在 `async_event_impl.hpp`。

## 三、信号同步：TNOTIFY / TWAIT / TTEST

跨 NPU 标志同步。信号类型：`Signal`（标量 `GlobalTensor<int32_t, Shape<1,1,1,1,1>>`）或 `Signal2D<Rows,Cols>`（编译期二维网格，支持带步长子区域视图）。

```cpp
comm::TNOTIFY(signal, 1, comm::NotifyOp::Set);   // 发送通知
comm::TWAIT(signal, 1, comm::WaitCmp::EQ);       // 阻塞等待条件
comm::TTEST(signal, 1, comm::WaitCmp::GE);       // 非阻塞检测
```

- **NotifyOp**：`Set`（signal=value）、`AtomicAdd`（signal+=value）
- **WaitCmp**：`EQ` `NE` `GT` `GE` `LT` `LE`

## 四、集合通信：TGATHER / TSCATTER / TBROADCAST / TREDUCE

由 root 发起，基于 `ParallelGroup` 封装各 rank 的 GlobalTensor 数组：

- `TGATHER` — 从所有 rank 收集数据并沿 DIM_3 拼接
- `TSCATTER` — 沿 DIM_3 拆分并分发到所有 rank
- `TBROADCAST` — 当前 NPU 数据广播到所有 rank
- `TREDUCE` — 从所有 rank 收集并逐元素归约到本地（`ReduceOp::Sum/Max/Min`）

```cpp
template <typename GlobalData>
struct ParallelGroup {
    GlobalData *tensors;   // 各 rank 的 GlobalData 数组（本地元数据，封装本地/远端 GM 地址）
    int nranks;            // rank 总数
    int rootIdx;           // root rank 索引
    static ParallelGroup Create(GlobalData *tensorArray, int size, int rank_id);
};
```

支持 2D 分块滑动 + ping-pong 双缓冲。

## 五、TPUT 原子写

`AtomicType`（定义于 `include/pto/common/constants.hpp`）：`AtomicNone`（默认）、`AtomicAdd`。

## 后端实现目录

```
include/pto/comm/
├── pto_comm_inst.hpp        # 公共 API（模板封装 + 事件处理）
├── pto_comm_instr_impl.hpp  # 编译期后端分发
├── comm_types.hpp           # ParallelGroup/Signal/Signal2D/NotifyOp/WaitCmp/ReduceOp/DmaEngine/AsyncEvent
├── a2a3/                     # A2/A3（910B/910C）：TPut/TGet/TNotify/... + async/（仅 SDMA）
├── a5/                       # A5（950）：同步指令复用 a2a3；async/（SDMA+MTE 回退+URMA）
└── async_common/            # 异步公共：async_types/async_event_impl/TPutAsyncCommonDetail/TGetAsyncCommonDetail
```

## 关联

- 概念：[[pto-overview]]、[[instruction-map]]、[[backend-and-arch]]、[[kernels-practice]]
- 硬件：[[sdma]]、[[urma]]、[[ccu]]、[[unified-bus]]
- 代码真源：`include/pto/comm/`、`docs/isa/comm/`
