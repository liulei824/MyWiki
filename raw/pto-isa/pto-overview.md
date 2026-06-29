# PTO / PTO-ISA 总览

- **来源**: `code/pto-isa-main` — `README_zh.md`、`docs/PTOISA_zh.md`、`docs/README_zh.md`、`docs/auto_mode/README_zh.md`
- **整理日期**: 2026-06-29
- **类型**: 自写综合笔记（基于官方仓库文档）

## 一句话定义

**PTO（Parallel Tile Operation）** 是昇腾 CANN 定义的一套**面向 tile 编程的虚拟 ISA**。`pto-isa` 仓库提供这套虚拟指令的实现、示例、测试与文档，目标是用更高层的 **Tile 抽象**桥接不同昇腾代际（A2/A3/A5）的硬件实现差异，在保持可移植的同时**保留性能调优空间**（不隐藏底层能力）。

- 远程仓：`https://gitcode.com/cann/pto-isa.git`
- 平台支持：Ascend **A2 / A3 / A5** + **CPU 仿真**
- 当前已定义 **90+ 条标准 tile 指令**（计算 + 数据搬运 + 通信扩展）

## 核心心智模型

### 1. Tile 是计算与搬运的基本单位

PTO 程序围绕 **Tile** 编写：Tile 是**固定容量的二维缓冲区**，位于片上 Tile 存储（类寄存器/SRAM），通过 `TLOAD`/`TSTORE` 在全局内存（GM）与片上之间搬运。大多数指令以「一个 Tile」为单位消费/产生数据。详见 [[tile-programming-model]]。

### 2. 典型 kernel = 阶段流水线

仓库里多数高性能 kernel 都可抽象成一条流水线：

```
TLOAD (GM→片上) → 布局变换(TEXTRACT/TMOV/TTRANS) → 计算(Cube TMATMUL / Vector 逐元素) → TSTORE (片上→GM)
```

优化的本质就是让这几个阶段**稳态重叠**、降低每 FLOP 的搬运字节、避免流水线气泡。详见 [[kernels-practice]]。

### 3. SPMD 执行模型

所有核执行同一份 kernel，由 `block_idx`（及可选 sub-block id）决定各自处理的数据切片。Tiling 与核间工作划分是一阶调优旋钮。

## 两种开发模式：Auto vs Manual

PTO 提供 **Auto / Manual 双路径**，这是理解 PTO 编程的关键分叉：

| 维度 | Manual 模式 | Auto 模式 |
|------|-------------|-----------|
| **Tile 内存分配** | 手动 `TASSIGN(tile, addr)` 指定片上地址 | 编译器自动分配到正确 buffer |
| **流水线同步** | 手动 `Event` / `set_flag`/`wait_flag` | 编译器自动插入同步，最大化 pipe 并行 |
| **跨架构差异** | 程序员需关心（尤其 Cube↔Vector 同步机制） | 编译器屏蔽，确保跨代兼容 |
| **优化控制力** | 最强，适合极致性能 | 较弱，降低开发难度 |
| **当前可用性** | NPU + CPU 仿真 | **主要可用于 CPU 仿真**；仅支持 `-O2` |

同一段逐元素乘法，Manual 模式需显式写 `TASSIGN` + `set_flag/wait_flag`，Auto 模式只写 `TLOAD/TMUL/TSTORE` 即可（编译器补全内存与同步）。源对比见 `docs/auto_mode/README_zh.md`。

> 实践建议：**先用 Auto/CPU 仿真快速验证逻辑正确性，再切 Manual 深入调优**。

## 三种后端

PTO 同一份源码可编译到三类后端（编译宏区分），详见 [[backend-and-arch]]：

| 后端 | 宏 | 用途 |
|------|-----|------|
| **CPU 仿真** | `__CPU_SIM` | 跨平台功能验证、开发调试；`TSYNC` 多为 no-op |
| **NPU 原生** | `__CCE_AICORE__` / `PTO_NPU_ARCH_A5` | 真实昇腾硬件执行 |
| **CostModel** | `__COSTMODEL` | 性能仿真（stub 行为验证 / fit 公式时延预测） |

## 指令体系速览

PTO 指令大致分为以下几类（完整分类导航见 [[instruction-map]]）：

- **计算类**：逐元素（Tile-Tile / Tile-标量）、轴归约与扩展、矩阵乘（matmul/gemv）、量化/转换
- **数据搬运/布局**：TLOAD/TSTORE/TMOV/TTRANS/TEXTRACT/TINSERT/TRESHAPE 等
- **核间通信**：TPipe FIFO（TALLOC/TPUSH/TPOP/TFREE），用于 Cube-Vector 通信
- **同步**：TSYNC（单流水线屏障）、SYNCALL（跨核屏障）
- **NPU 间通信扩展**：点对点（TPUT/TGET 及 *_ASYNC）、信号（TNOTIFY/TWAIT/TTEST）、集合（TGATHER/TSCATTER/TREDUCE/TBROADCAST），详见 [[comm-isa]]

## 仓库与生态

- 上层框架已集成：**PyPTO**（`gitcode.com/cann/pypto`）、**TileLang Ascend**（`github.com/tile-ai/tilelang-ascend`）
- 权威 C++ intrinsic 头：`include/pto/common/pto_instr.hpp`（计算）、`include/pto/comm/pto_comm_inst.hpp`（通信）

## 关联

- 概念：[[tile-programming-model]]、[[instruction-map]]、[[backend-and-arch]]、[[comm-isa]]、[[kernels-practice]]
- 实体：[[cann]]、[[ascend-950]]
- 代码真源：`code/pto-isa-main`（回查见 `raw/cann-open-source-repos.md`）
