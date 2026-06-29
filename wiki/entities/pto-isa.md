# pto-isa

- **类型**: 框架
- **首次记录**: 2026-06-29
- **来源数**: 2

## 概述

**PTO（Parallel Tile Operation）** 是 [[cann]] 定义的一套**面向 tile 编程的虚拟 ISA**；`pto-isa` 仓库提供这套虚拟指令的实现、示例、测试与文档。目标是用更高层的 **Tile 抽象**桥接昇腾不同代际（A2/A3/A5）的硬件实现差异，在保持可移植的同时**保留性能调优空间**（不隐藏底层能力）。

- 远程仓：`https://gitcode.com/cann/pto-isa.git`（本地主开发副本 `code/pto-isa-main`）
- 平台：Ascend **A2 / A3 / A5** + **CPU 仿真**
- 规模：已定义 **90+ 条标准 tile 指令**（计算 + 数据搬运 + 通信扩展）

## 关键事实

- **编程基本单位是 [[pto-tile|Tile]]**：固定容量二维缓冲区，经 `TLOAD`/`TSTORE` 在 GM 与片上之间搬运。
- **双开发模式**：Manual（手动内存/同步，极致调优）与 Auto（编译器补全，主要在 CPU 仿真）。
- **三后端同源**（见 [[pto-backend]]）：CPU 仿真 / NPU 原生 / CostModel，由编译宏分发。
- **指令体系**（见 [[pto-instruction-set]]）：同步、逐元素、轴归约、内存、矩阵乘、布局搬运、复杂指令、核间 FIFO、NPU 间通信。
- **通信扩展**（见 [[pto-comm-isa]]）：点对点（[[sdma]]/[[urma]]）+ 集合（[[ccu]]）。
- **上层框架**：PyPTO（`gitcode.com/cann/pypto`）、TileLang Ascend（`github.com/tile-ai/tilelang-ascend`）。
- **权威 intrinsic 头**：`include/pto/common/pto_instr.hpp`（计算）、`include/pto/comm/pto_comm_inst.hpp`（通信）。

## 相关

- 实体：[[cann]]、[[ascend-950]]
- 概念：[[pto-tile]]、[[pto-instruction-set]]、[[pto-backend]]、[[pto-comm-isa]]、[[pto-kernel-optimization]]
- 资料：[[source-pto-isa]]、[[source-pto-comm]]
- 代码真源：`code/pto-isa-main`（回查见 `raw/cann-open-source-repos.md`）
