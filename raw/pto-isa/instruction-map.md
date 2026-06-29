# PTO 指令体系地图（分类导航）

- **来源**: `code/pto-isa-main` — `docs/PTOISA_zh.md`、`docs/isa/README_zh.md`、`docs/isa/comm/README_zh.md`
- **整理日期**: 2026-06-29
- **类型**: 自写综合笔记（分类导航，非逐条指令参考）

> 本页是**导航图**，不复制逐条指令的完整语义。逐指令参考见 `code/pto-isa-main/docs/isa/<指令>_zh.md`（约 200 个页面）。权威 C++ intrinsic 源：`include/pto/common/pto_instr.hpp`（计算）、`include/pto/comm/pto_comm_inst.hpp`（通信）。

## 速查：按「我想做什么」找指令

| 我想… | 用这类指令 | 典型代表 |
|-------|-----------|----------|
| GM 与片上之间搬数据 | 内存（GM↔Tile） | `TLOAD` / `TSTORE` |
| 逐元素算术/逻辑 | 逐元素 | `TADD` / `TMUL` / `TSEL` |
| 行/列方向归约 | 轴归约 | `TROWSUM` / `TCOLMAX` |
| 矩阵乘 | 矩阵乘 | `TMATMUL` / `TGEMV` |
| 改布局/转置/提取子块 | 数据搬运/布局 | `TTRANS` / `TEXTRACT` / `TINSERT` |
| 类型转换/量化 | 转换/量化 | `TCVT` / `TQUANT` |
| 排序/gather/随机 | 复杂指令 | `TSORT32` / `TGATHER` / `TRANDOM` |
| Cube↔Vector 核内通信 | 核间通信 FIFO | `TPUSH` / `TPOP` |
| 流水线/跨核同步 | 同步 | `TSYNC` / `SYNCALL` |
| NPU 之间传数据 | 通信扩展 | `TPUT` / `TGET`（见 [[comm-isa]]） |

## 分类详解

### 1. 同步

- `TSYNC` — 同步 PTO 执行（等事件或插入单 op 流水线屏障）
- `SYNCALL` — 跨核同步屏障（硬件 FFTS 或软件 GM 轮询）

### 2. 手动 / 资源绑定（Manual 模式相关）

- `TASSIGN` — 把 Tile 绑定到实现定义片上地址（手动放置）
- `SETFMATRIX` / `SET_IMG2COL_RPT` / `SET_IMG2COL_PADDING` — IMG2COL（类卷积）配置寄存器
- `SET_QUANT_SCALAR` / `SET_QUANT_VECTOR` — 设置标量/向量量化参数（供后续 `TPUSH`）

### 3. 逐元素（Tile-Tile）

两个 Tile（或一元）逐元素运算：

- 算术：`TADD` `TSUB` `TMUL` `TDIV` `TMIN` `TMAX` `TADDC`(三元 src0+src1+src2) `TSUBC`(src0-src1+src2)
- 融合：`TMULADDDST`(src0*src1+dst) `TFUSEDMULADD`(src0*dst+src1) `TFUSEDMULADDRELU` `TSUBRELU`
- 位运算：`TAND` `TOR` `TXOR` `TNOT` `TSHL` `TSHR`
- 数学：`TEXP` `TLOG` `TPOW` `TSQRT` `TRSQRT` `TRECIP` `TREM`(符号随除数) `TFMOD`(符号随被除数)
- 激活/选择：`TRELU` `TPRELU` `TNEG` `TABS` `TSEL`(掩码选择) `TCMP`(比较→谓词掩码) `TCVT`(类型转换+舍入)

### 4. Tile-标量 / Tile-立即数

逐元素 op 的「Tile vs 标量」版本（后缀 `S`）：

- `TADDS` `TSUBS` `TMULS` `TDIVS` `TMINS` `TMAXS` `TANDS` `TORS` `TXORS` `TSHLS` `TSHRS`
- `TEXPANDS`(标量广播到 Tile) `TCMPS` `TSELS` `TFMODS` `TREMS` `TPOWS` `TLRELU`(标量斜率 LeakyReLU)
- 融合：`TADDSC`(src0+scalar+src1) `TSUBSC`(src0-scalar+src1)

### 5. 轴归约 / 扩展

- **行归约**：`TROWSUM` `TROWPROD` `TROWMAX` `TROWMIN` `TROWARGMAX` `TROWARGMIN`
- **列归约**：`TCOLSUM` `TCOLPROD` `TCOLMAX` `TCOLMIN` `TCOLARGMAX` `TCOLARGMIN`
- **行广播扩展**（每行一个标量向量）：`TROWEXPAND` `TROWEXPANDADD/SUB/MUL/DIV/MAX/MIN` `TROWEXPANDEXPDIF`(exp(src0-src1))
- **列广播扩展**：`TCOLEXPAND` `TCOLEXPANDADD/SUB/MUL/DIV/MAX/MIN` `TCOLEXPANDEXPDIF`

> Softmax 类算子常用：`TROWMAX` → `TROWEXPANDEXPDIF` → `TROWSUM` → `TROWEXPANDDIV`。

### 6. 内存（GM ↔ Tile）

- `TLOAD` — GM → Tile
- `TSTORE` — Tile → GM（可选原子写 / 量化参数）；`TSTORE_FP` — 累加器 Tile + 缩放 Tile 存回
- `TPREFETCH` — 预取提示到片上；`TPREFETCH_ASYNC` — 经 SDMA CMO 异步预取 GM→L2
- `MGATHER` / `MSCATTER` — 按逐元素索引从 GM gather / 向 GM scatter

### 7. 矩阵乘

- `TMATMUL` — GEMM 生成累加器/输出；`TMATMUL_ACC`(融合累加) `TMATMUL_BIAS`(+偏置) `TMATMUL_MX`(混合精度/量化，带缩放 Tile)
- `TGEMV` — 矩阵-向量；`TGEMV_ACC` `TGEMV_BIAS` `TGEMV_MX`

### 8. 数据搬运 / 布局

- 提取/插入：`TEXTRACT`(+`_FP`) `TINSERT`(+`_FP`) `TSUBVIEW`(子视图) `TCONCAT`(列拼接)
- 变形：`TMOV`(+`_FP`) `TRESHAPE`(重解释字节) `TTRANS`(转置) `TGET_SCALE_ADDR`
- 填充：`TFILLPAD` `TFILLPAD_INPLACE` `TFILLPAD_EXPAND`
- 卷积：`TIMG2COL`
- 交织：`TInterleave` / `TDeInterleave` / `TPAIRREDUCESUM`(相邻两元素求和)

### 9. 复杂指令

- 排序：`TSORT32`(每 32 元素块带 idx 排序) `TMRGSORT`(归并排序)
- gather/scatter：`TGATHER`(索引/掩码) `TGATHERB`(字节偏移) `TSCATTER`(按行索引散播)
- 生成：`TCI`(连续整数) `TTRI`(三角掩码) `TRANDOM`(计数器密码随机)
- 部分运算（有效区域不匹配处理为实现定义）：`TPARTADD` `TPARTMUL` `TPARTMAX` `TPARTMIN` `TPARTARGMAX` `TPARTARGMIN`
- 量化：`TQUANT`(如 FP32→FP8，产出指数/缩放/最大值)
- 调试：`TPRINT`

### 10. 核间通信（Cube-Vector via TPipe FIFO）

用于 AI Core 内部 Cube↔Vector 通过 FIFO 交换 tile：

- `TALLOC` — 将 TPipe FIFO 槽位分配为 GlobalTensor 视图
- `TPUSH` — 生产者 tile 推入 FIFO
- `TPOP` — 消费者从 FIFO 弹出 tile/globalTensor
- `TFREE` — 释放 FIFO 空间（对 TileData/GlobalTensor 的 TPOP 流程为 no-op）

### 11. NPU 间通信扩展

点对点 / 信号 / 集合通信，单列一篇详解 → [[comm-isa]]。

## 关联

- 概念：[[pto-overview]]、[[tile-programming-model]]、[[comm-isa]]
- 逐指令参考：`code/pto-isa-main/docs/isa/`
