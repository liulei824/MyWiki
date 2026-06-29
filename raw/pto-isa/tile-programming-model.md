# PTO Tile 编程模型与事件同步

- **来源**: `code/pto-isa-main` — `docs/coding/Tile_zh.md`、`docs/coding/Event_zh.md`；头文件 `include/pto/common/pto_tile.hpp`、`include/pto/common/pto_instr.hpp`、`include/pto/common/event.hpp`
- **整理日期**: 2026-06-29
- **类型**: 自写综合笔记（基于官方仓库文档）

## 一、Tile 是什么

**Tile = 固定容量的二维缓冲区**，是大多数 PTO 指令的计算单元，也是数据搬运的基本单位。概念上 Tile 位于**片上 Tile 存储**（类寄存器/SRAM），通过 `TLOAD`/`TSTORE` 与 GM 交换数据。CPU 仿真后端把 Tile 放主机内存，但保持相同的形状/布局/有效区域规则以验证语义。

一个 Tile 由五类属性刻画：

| 属性 | 含义 |
|------|------|
| **位置 Location** | 逻辑/物理存储类（向量 vs 矩阵寄存器类） |
| **元素类型 Element** | `float` / `half` / `int8_t` 等 |
| **容量形状 Capacity** | 编译期固定的 `Rows × Cols` |
| **布局 Layout** | 基础布局 `BLayout` + 可选盒化/分形 `SLayout` / `SFractalSize` |
| **有效区域 Valid region** | 本次操作中有意义的行/列数（静态或动态） |

## 二、`pto::Tile` 模板

```cpp
pto::Tile<
  pto::TileType Loc_,
  Element_,
  Rows_,
  Cols_,
  pto::BLayout BLayout_   = pto::BLayout::RowMajor,
  RowValid_               = Rows_,
  ColValid_               = Cols_,
  pto::SLayout SLayout_   = pto::SLayout::NoneBox,
  SFractalSize_           = pto::TileConfig::fractalABSize,
  pto::PadValue PadValue_ = pto::PadValue::Null
>;
```

### 位置 `TileType`（参与重载选择与编译期检查）

| 值 | 含义 |
|----|------|
| `TileType::Vec` | 向量 Tile 存储（UB / vector pipeline） |
| `TileType::Mat` | 通用矩阵 Tile（Matrix L1） |
| `TileType::Left` / `Right` | 矩阵乘操作数（Matrix L0A / L0B） |
| `TileType::Acc` | 矩阵乘累加器 |
| `TileType::Bias` / `Scaling` | matmul/move 辅助 Tile |

各指令允许哪些位置类型，以 `docs/isa/` 指令页声明为准。

### 容量形状 vs 有效区域

- **容量** `Rows_/Cols_`：静态，编译期特化与优化的基础。
- **有效区域** `(valid_row, valid_col)`：哪些元素本次有意义。
  - `RowValid_==Rows_ && ColValid_==Cols_` → 完全静态。
  - 任一为 `pto::DYNAMIC`（`-1`）→ 运行期存于 Tile 对象，`GetValidRow()/GetValidCol()` 查询。
- **关键约束**：有效区域总是**连续前缀**（`0<=i<validRow`, `0<=j<validCol`）；区域外元素除非指令显式定义 padding，否则**未指定**。

### 布局：两层结构

- **基础布局 `BLayout`**（`RowMajor`/`ColMajor`）：外层矩阵解释。
- **盒化/分形 `SLayout`**（`NoneBox`/`RowMajor`/`ColMajor`）：是否把 Tile 内部划分为固定大小「基块」(base tile / fractal)。
- **基块大小 `SFractalSize`**：常用 `TileConfig::fractalABSize = 512` 字节（A/B 操作数）、`fractalCSize = 1024` 字节（累加器）。

**为什么要盒化**：部分矩阵引擎偏好固定基块访问模式；显式表达可让编译器尽早选合法布局、避免运行时慢速 fixup、便于跨代际映射。

512 字节基块（内层 row-major）示例：

| 类型 | 基块形状 | 字节数 |
|------|----------|--------|
| fp32 | 16×8 | 16·8·4 = 512 |
| fp16 | 16×16 | 16·16·2 = 512 |
| int8/fp8 | 16×32 | 16·32·1 = 512 |

### 编译期约束（`static_assert` 强制）

- 未盒化 row-major：`Cols * sizeof(Element)` 必须是 `TileConfig::alignedSize`（**32 字节**）整数倍。
- 未盒化 col-major：`Rows * sizeof(Element)` 必须是 32 字节整数倍。
- 盒化 Tile：形状须与 `(SLayout, SFractalSize)` 隐含的基块维度兼容（部分 `Vec` Tile 有小例外）。

这些约束是有意为之：阻止生成在真实硬件上非法或低效的程序。

### 常用别名

`include/pto/common/pto_tile.hpp` 提供 matmul 便捷别名（自动选盒化布局/分形大小）：

- `TileLeft<Element,Rows,Cols>` — 外 col-major + 内 row-major（"Nz"）
- `TileRight<Element,Rows,Cols>` — 外 row-major + 内 col-major（"Zn"）
- `TileAcc<Element,Rows,Cols>` — 用 `fractalCSize` 的累加器布局

### 地址绑定 `TASSIGN`

- **Manual 流程**：`TASSIGN(tile, addr)` 把 Tile 绑定到实现定义地址。
- **Auto 流程**：可能因构建配置成为 no-op（编译器自动分配）。

## 三、事件与同步模型

PTO 用**显式事件**表达操作间依赖，而非给每条指令加全局屏障。

> 注意：`pto::Event<SrcOp, DstOp>` 仅在设备构建（`__CCE_AICORE__`）定义；CPU 仿真把 `TSYNC` 当 no-op，靠单线程程序顺序验证语义。

### 关键类型

| 类型 | 作用 |
|------|------|
| `pto::Op` | 类 opcode 枚举，每个 Op 映射一条硬件流水线（`PIPE_V`、`PIPE_MTE2` …） |
| `pto::RecordEvent` | 多数 intrinsic（`TADD`/`TLOAD`/`TSTORE`）返回的标记值，可赋给 `Event` 记录 token |
| `pto::Event<SrcOp,DstOp>` | 设备侧事件：`Wait()` 阻塞至 producer token 满足；`Record()` 在 producer 流水线设 token；`evt = OP(...)` 自动记录 |
| `TSYNC<OpCode>()` | 单 op 屏障；设备上当前限 `PIPE_V`，CPU 仿真为 no-op |

### SSA 风格写法

intrinsic 末尾常带 `WaitEvents&... events` 可变参包：调用时先 `TSYNC(events...)` → `WaitAllEvents` 逐个 `Wait()`，执行后返回 `RecordEvent`。于是可以：

1. 把 event token 存为 C++ 变量
2. 传给下一条 op 表达顺序约束
3. 用返回的 `RecordEvent` 赋值记录新 token

### 最小示例

```cpp
#include <pto/pto-inst.hpp>
using namespace pto;

void pipeline(__gm__ float* in0, __gm__ float* in1, __gm__ float* out) {
  using TileT  = Tile<TileType::Vec, float, 16, 16>;
  using GShape = Shape<1, 1, 1, 16, 16>;
  using GStride= BaseShape2D<float, 16, 16, Layout::ND>;
  using GT     = GlobalTensor<float, GShape, GStride, Layout::ND>;

  GT gin0(in0), gin1(in1), gout(out);
  TileT a, b, c;

  Event<Op::TLOAD, Op::TADD> e0, e1;
  Event<Op::TADD, Op::TSTORE_VEC> e2;

  e0 = TLOAD(a, gin0);
  e1 = TLOAD(b, gin1);
  e2 = TADD(c, a, b, e0, e1);   // 等待 e0/e1，记录 e2
  TSTORE(gout, c, e2);          // 等待 e2
}
```

### 顺序建议

- 事件主要表达**流水线类之间**的顺序（如"load 完成后 vector 才能消费该 Tile"）。
- 无显式依赖的 op 在设备上可能乱序执行。
- 只等**真实依赖**，避免稳态循环里做全局 drain。

## 关联

- 概念：[[pto-overview]]、[[instruction-map]]、[[backend-and-arch]]、[[kernels-practice]]
- 代码真源：`include/pto/common/pto_tile.hpp`、`event.hpp`、`pto_instr.hpp`
