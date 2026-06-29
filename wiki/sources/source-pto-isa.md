# PTO-ISA 核心笔记（总览 / 编程模型 / 指令 / 后端 / 优化）

- **来源**: `raw/pto-isa/pto-overview.md`、`tile-programming-model.md`、`instruction-map.md`、`backend-and-arch.md`、`kernels-practice.md`（均自写综合，事实源 `code/pto-isa-main`）
- **导入日期**: 2026-06-29
- **类型**: 笔记

## 核心要点

- **PTO（Parallel Tile Operation）** 是 CANN 定义的面向 tile 编程的**虚拟 ISA**，用 Tile 抽象桥接 A2/A3/A5 代际差异，保可移植又保留调优空间；已定义 90+ 条标准 tile 指令。
- **Tile = 固定容量二维缓冲区**，是计算与搬运的基本单位；由位置/元素类型/容量/布局/有效区域五类属性刻画，编译期 `static_assert` 强制对齐与盒化约束。
- **Auto vs Manual 双模式**：Manual 手动 `TASSIGN` + event/flag，控制力最强；Auto 由编译器补全内存与同步，主要可用于 CPU 仿真。
- **三后端同源**：CPU 仿真（`__CPU_SIM`）、NPU 原生（`__CCE_AICORE__` / `PTO_NPU_ARCH_A5`）、CostModel（`__COSTMODEL`，stub 行为 + fit 时延）。
- **事件同步模型**：用显式 `pto::Event<SrcOp,DstOp>` + `RecordEvent` 表达流水线依赖，SSA 风格，只等真实依赖。
- **性能心智**：kernel = TLOAD→布局变换→计算(Cube/Vector)→TSTORE 流水线；优化即最大化稳态重叠、降每 FLOP 搬运字节、消气泡。

## 详细摘要

PTO 程序围绕 Tile 编写，典型高性能 kernel 抽象成阶段流水线，SPMD 由 `block_idx` 切分数据。指令体系分为：同步（`TSYNC`/`SYNCALL`）、逐元素（Tile-Tile / Tile-标量）、轴归约与广播扩展（Softmax 友好）、内存（`TLOAD`/`TSTORE`/`TPREFETCH`/`MGATHER`）、矩阵乘（`TMATMUL`/`TGEMV` 及 ACC/BIAS/MX 变体）、数据搬运布局（`TTRANS`/`TEXTRACT`/`TRESHAPE` 等）、复杂指令（排序/gather/随机/量化）、核间通信 TPipe FIFO（`TALLOC`/`TPUSH`/`TPOP`/`TFREE`），以及 NPU 间通信扩展（详见 [[source-pto-comm]]）。

后端按编译宏分发：`include/pto/common/` 公共，`cpu/` 仿真，`npu/`（a2a3/a5/kirin）原生，`comm/` 通信，`costmodel/` 性能模型。SoC 由测试脚本 `-v a3|a5` 选择。调优围绕四杠杆：并行性（核划分）、Tiling（放得下且可复用）、数据搬运（减流量/少变换）、重叠与同步（双缓冲）。

## 关联

- 实体：[[pto-isa]]、[[cann]]、[[ascend-950]]
- 概念：[[pto-tile]]、[[pto-instruction-set]]、[[pto-backend]]、[[pto-kernel-optimization]]、[[pto-comm-isa]]
- 相关摘要：[[source-pto-comm]]

## 与已有知识的关联

- **补充**：在 [[cann]] 软件栈之上补齐「tile 级虚拟 ISA」这一层，连接 [[davinci-core-gen3]]（[[cube-core]]/[[vector-core]]）的硬件能力与上层算子开发。
- **矛盾**：无。
