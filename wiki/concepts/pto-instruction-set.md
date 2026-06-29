# pto-instruction-set

- **领域**: PTO-ISA 指令体系
- **首次记录**: 2026-06-29
- **来源数**: 1

## 定义

[[pto-isa]] 已定义 90+ 条标准 tile 指令。本页是**分类导航图**，逐指令完整语义见 `code/pto-isa-main/docs/isa/<指令>_zh.md`，权威源 `include/pto/common/pto_instr.hpp`（计算）与 `include/pto/comm/pto_comm_inst.hpp`（通信）。

## 核心内容

### 按「想做什么」找指令

| 想做… | 类别 | 代表 |
|-------|------|------|
| GM↔片上搬数据 | 内存 | `TLOAD` / `TSTORE` |
| 逐元素算术/逻辑 | 逐元素 | `TADD` / `TMUL` / `TSEL` |
| 行/列归约 | 轴归约 | `TROWSUM` / `TCOLMAX` |
| 矩阵乘 | 矩阵乘 | `TMATMUL` / `TGEMV` |
| 改布局/转置/提取 | 布局搬运 | `TTRANS` / `TEXTRACT` / `TINSERT` |
| 类型转换/量化 | 转换/量化 | `TCVT` / `TQUANT` |
| 排序/gather/随机 | 复杂指令 | `TSORT32` / `TGATHER` / `TRANDOM` |
| Cube↔Vector 核内通信 | 核间 FIFO | `TPUSH` / `TPOP` |
| 流水线/跨核同步 | 同步 | `TSYNC` / `SYNCALL` |
| NPU 之间传数据 | 通信扩展 | `TPUT` / `TGET`（见 [[pto-comm-isa]]） |

### 分类速览

- **同步**：`TSYNC`（单 op 屏障/等事件）、`SYNCALL`（跨核屏障，FFTS 或 GM 轮询）。
- **手动/资源绑定**：`TASSIGN`、IMG2COL 配置（`SETFMATRIX` 等）、量化参数（`SET_QUANT_*`）。
- **逐元素（Tile-Tile）**：算术 `TADD/TSUB/TMUL/TDIV/TMIN/TMAX` + 融合 `TMULADDDST` 等；位运算 `TAND/TOR/...`；数学 `TEXP/TLOG/TSQRT/...`；激活/选择 `TRELU/TSEL/TCMP/TCVT`。
- **Tile-标量**（后缀 `S`）：`TADDS/TMULS/...`、`TEXPANDS`、`TLRELU` 等。
- **轴归约/扩展**：行 `TROW*`、列 `TCOL*`、广播扩展 `TROWEXPAND*`/`TCOLEXPAND*`（Softmax 常用 `TROWMAX→TROWEXPANDEXPDIF→TROWSUM→TROWEXPANDDIV`）。
- **内存**：`TLOAD`/`TSTORE`(+`_FP`)、`TPREFETCH`(+`_ASYNC` 经 SDMA CMO)、`MGATHER`/`MSCATTER`。
- **矩阵乘**：`TMATMUL`(+`_ACC`/`_BIAS`/`_MX`)、`TGEMV` 同族。
- **布局搬运**：`TEXTRACT`/`TINSERT`/`TSUBVIEW`/`TCONCAT`、`TMOV`/`TRESHAPE`/`TTRANS`、`TFILLPAD*`、`TIMG2COL`、`TInterleave`。
- **复杂指令**：排序 `TSORT32`/`TMRGSORT`；gather/scatter `TGATHER(B)`/`TSCATTER`；生成 `TCI`/`TTRI`/`TRANDOM`；部分运算 `TPART*`；量化 `TQUANT`；调试 `TPRINT`。
- **核间通信（TPipe FIFO）**：`TALLOC`/`TPUSH`/`TPOP`/`TFREE`，用于 Cube↔Vector 交换 tile。
- **NPU 间通信扩展**：点对点/信号/集合 → [[pto-comm-isa]]。

## 相关

- 实体：[[pto-isa]]
- 概念：[[pto-tile]]、[[pto-comm-isa]]、[[pto-backend]]、[[pto-kernel-optimization]]
- 资料：[[source-pto-isa]]
