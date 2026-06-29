# pto-tile

- **领域**: PTO-ISA 编程模型
- **首次记录**: 2026-06-29
- **来源数**: 1

## 定义

**Tile** 是 [[pto-isa]] 的核心抽象：**固定容量的二维缓冲区**，既是大多数指令的计算单元，也是数据搬运的基本单位。概念上位于片上 Tile 存储（类寄存器/SRAM），经 `TLOAD`/`TSTORE` 与全局内存（GM）交换。CPU 仿真把 Tile 放主机内存，但保持相同形状/布局/有效区域规则。

## 核心内容

### 五类属性

| 属性 | 含义 |
|------|------|
| 位置 Location（`TileType`） | `Vec` / `Mat` / `Left` / `Right` / `Acc` / `Bias` / `Scaling`，参与重载选择与编译期检查 |
| 元素类型 Element | `float` / `half` / `int8_t` 等 |
| 容量形状 Capacity | 编译期固定 `Rows × Cols` |
| 布局 Layout | 基础 `BLayout`（行/列主序）+ 可选盒化/分形 `SLayout` / `SFractalSize` |
| 有效区域 Valid region | 本次操作有意义的行/列（静态或 `DYNAMIC`）；恒为**连续前缀** |

### 容量 vs 有效区域

- 容量静态，是特化与优化基础；有效区域可运行期查询（`GetValidRow()/GetValidCol()`）。
- 区域外元素除非指令显式定义 padding 否则**未指定**。

### 盒化（fractal）

部分矩阵引擎偏好固定基块访问。常用基块 512B（A/B 操作数）、1024B（累加器）。显式表达让编译器尽早选合法布局、避免运行时 fixup。便捷别名：`TileLeft`/`TileRight`/`TileAcc`。

### 编译期约束（`static_assert`）

- 未盒化 row-major：`Cols * sizeof(Element)` 须为 32 字节整数倍；col-major 对 `Rows` 同理。
- 盒化 Tile 形状须与 `(SLayout, SFractalSize)` 兼容。

### 地址绑定

`TASSIGN(tile, addr)` 在 Manual 流程绑定片上地址；Auto 流程下可能为 no-op（编译器自动分配）。

## 事件与同步模型

PTO 用**显式事件**（而非全局屏障）表达依赖：

- `pto::Op`：类 opcode 枚举，映射硬件流水线（`PIPE_V`/`PIPE_MTE2` …）。
- `pto::Event<SrcOp,DstOp>`：`Wait()` 阻塞至 producer token 满足，`evt = OP(...)` 自动记录。
- `RecordEvent`：intrinsic 返回的 token，可存为 C++ 变量传给下一条 op（SSA 风格）。
- `TSYNC<OpCode>()`：单 op 屏障（设备上限 `PIPE_V`，CPU 仿真 no-op）。
- 原则：只等**真实依赖**，避免稳态循环里全局 drain。

> `pto::Event` 仅设备构建（`__CCE_AICORE__`）定义；CPU 仿真靠单线程程序顺序验证。

## 相关

- 实体：[[pto-isa]]
- 概念：[[pto-instruction-set]]、[[pto-backend]]、[[pto-kernel-optimization]]、[[pto-comm-isa]]
- 资料：[[source-pto-isa]]
