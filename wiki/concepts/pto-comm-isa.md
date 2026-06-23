# pto-comm-isa

- **类型**: 概念
- **领域**: PTO / CANN 通信编程
- **首次记录**: 2026-06-24
- **来源数**: 1

## 定义

**PTO 通信 ISA** 是 [[pto-isa]] 中面向 **NPU 间**数据传输、信号同步与集合通信的指令扩展，与计算 Tile 指令共用 Tile 抽象。权威文档：`docs/isa/comm/README_zh.md`；API：`include/pto/comm/pto_comm_inst.hpp`。

> 注意：与 **Cube-Vector 核内 FIFO**（`TPUSH`/`TPOP`/`TALLOC`，见 `docs/isa/`「核间通信」节）不同——后者是单 NPU 内 AIC/AIV 通信，本页指 **多 NPU / 多 rank** 通信。

## 架构分层

```
用户 Kernel
    ↓
pto_comm_inst.hpp          ← 公共 API（TPUT/TGET/…/TPUT_ASYNC）
    ↓
pto_comm_instr_impl.hpp    ← 编译期分发
    ├── PTO_NPU_ARCH_A5  → a5/（Ascend 950）
    ├── __CCE_AICORE__   → a2a3/（910B/C）
    └── __CPU_SIM        → cpu/comm/ stubs
```

A5 同步指令多 **include a2a3 实现**；异步路径 A5 增强 **SDMA + URMA**。

## 指令分类速查

### 点对点（同步）

| 指令 | 语义 | 数据路径 |
|------|------|----------|
| **TPUT** | 远程写 | 本地 GM → UB Tile → 远端 GM |
| **TGET** | 远程读 | 远端 GM → UB Tile → 本地 GM |

- 支持单缓冲 / **ping-pong 双缓冲**（重叠 TLOAD/TSTORE）
- `TPUT` 可选 `AtomicAdd` 原子加
- 大张量自动 **二维滑动分块**（DIM_3/DIM_4）

### 点对点（异步）

| 指令 | 语义 | 引擎 |
|------|------|------|
| **TPUT_ASYNC** | 异步远程写 | SDMA（默认）；A5 还可 **URMA** |
| **TGET_ASYNC** | 异步远程读 | SDMA；A5 上 SDMA **仅 TGET**；URMA 读写均可 |

- 返回 **`AsyncEvent`**，`.Wait(session)` / `.Test(session)` 同步
- 需预先 **`BuildAsyncSession<engine>()`** 构建 `AsyncSession`
- SDMA 异步路径：**仅支持扁平连续一维 tensor**
- URMA：仅 **Ascend950（NPU_ARCH 3510）**，见 [[urma]]

**CANN 版本要求**（测试文档）：
- 同步指令：CANN **8.x+**
- 异步指令：CANN **9.0+**

### 信号同步

| 指令 | 语义 |
|------|------|
| **TNOTIFY** | 向远端发送通知（`Set` / `AtomicAdd`） |
| **TWAIT** | 阻塞等待 signal 条件（EQ/NE/GT/GE/LT/LE） |
| **TTEST** | 非阻塞检测 signal |

- Signal：`GlobalTensor<int32_t>` 标量或 **Signal2D** 网格

### 集合通信

由 **root rank** 发起，基于 **`ParallelGroup<GlobalData>`**（各 rank 的 GlobalTensor 数组）：

| 指令 | 语义 |
|------|------|
| **TGATHER** | root 从所有 rank **收集** |
| **TSCATTER** | root 向所有 rank **分发** |
| **TBROADCAST** | root **广播**到所有 rank |
| **TREDUCE** | root **归约**（Sum/Max/Min）到本地 |

- 支持 2D 分块滑动、ping-pong 双缓冲
- A5 另有 **CCU 硬件路径**测试：`tbroadcast_ccu`、`tgather_ccu`、`tscatter_ccu`、`treduce_ccu` → [[ccu]]

## 核心类型

| 类型 | 用途 |
|------|------|
| `ParallelGroup<GlobalData>` | 集合通信 rank 视图（tensors, nranks, rootIdx） |
| `Signal` / `Signal2D` | 跨 NPU 标志同步 |
| `AsyncEvent` | 异步传输完成句柄 |
| `AsyncSession` | SDMA/URMA 会话（`BuildAsyncSession` 构建） |
| `DmaEngine` | `SDMA` / `URMA` |
| `ReduceOp` | Sum / Max / Min |
| `NotifyOp` | Set / AtomicAdd |
| `WaitCmp` | EQ / NE / GT / GE / LT / LE |

## 与昇腾硬件的映射

| PTO 通信 | 昇腾950 wiki 概念 |
|----------|------------------|
| TPUT_ASYNC/TGET_ASYNC + URMA | [[urma]]、[[unified-bus]] |
| TPUT_ASYNC/TGET_ASYNC + SDMA | [[sdma]]、[[stars2]] |
| *_ccu 测试 / 集合通信卸载 | [[ccu]] |
| Manual fused kernel | [[cv-fusion]] 思想类似（计算通信融合） |

## 测试与示例

```bash
# 通信 ST（同步默认，-a 含异步）
./tests/run_comm_test.sh -v a5 -t tput
./tests/run_comm_test.sh -v a5 -a -t tput_async

# Manual：通信+计算融合
kernels/manual/a5/gemm_ar/          # GEMM + AllReduce
kernels/manual/a5/allgather_gemm/   # AllGather + GEMM
kernels/manual/a5/moe_dispatch/     # MoE dispatch
```

## 源码索引（镜像内）

| 文件 | 内容 |
|------|------|
| `include/pto/comm/pto_comm_inst.hpp` | 全部通信 API |
| `include/pto/comm/comm_types.hpp` | 公共类型 |
| `include/pto/comm/a5/async/TPutAsync.hpp` | A5 异步 PUT |
| `include/pto/comm/async_common/` | SDMA/URMA 公共异步逻辑 |
| `docs/isa/comm/TPUT_zh.md` 等 | 逐指令参考 |

## 相关

- 实体：[[pto-isa]]、[[cann]]、[[ascend-950]]
- 概念：[[urma]]、[[sdma]]、[[ccu]]、[[unified-bus]]、[[cv-fusion]]
- 资料：[[source-pto-isa-overview]]、[[source-pto-isa-comm-isa]]
- 登记：[[cann-ecosystem-manifest]]
