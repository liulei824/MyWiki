# ascend-950

- **类型**: 硬件
- **首次记录**: 2026-06-23
- **来源数**: 1

## 概述

昇腾950系列是华为面向下一代 AI 应用的旗舰 NPU，含 **昇腾950PR** 与 **昇腾950DT** 两款，基于 [[davinci-core-gen3]]，全栈自主制造工艺。

## 产品差异

| 型号 | 片上内存 | 带宽 | 主要场景 |
|------|----------|------|----------|
| **950PR** | 最高 128GB | 1.6TB/s | 高性能推荐、大模型 Prefill、多模态推理 |
| **950DT** | 最高 144GB | 4TB/s | 大模型预训练、后训练、推理（Decode+Prefill） |

## 关键规格（满配参考）

- 36 个 AI 子系统（每子系统 1 Cube + 2 Vector）
- 4 个 AI CPU Cluster（[[linx816]]）
- 4 个 [[dvpp]] 子系统
- 128MB 统一 [[l2-cache]]
- 72 Lane HiLink，整芯片互联带宽峰值 2TB/s
- [[stars2]] 调度；[[unified-bus]] 2.0 互联

### 算力示例（950DT 满配）

- MXFP4：2007 TFLOPS（Cube+Vector 合计）
- HiF8/MXFP8/FP8：1034 TFLOPS
- BF16/FP16：547 TFLOPS

## 物理架构

详见 [[chiplet-uma]]：2×AI Die + 2×IO Die + 片上内存模块（PR 8 / DT 4）。

## 相关

- 概念：[[davinci-core-gen3]]、[[unified-bus]]、[[ascend-super-node]]、[[hif8]]、[[nddma]]、[[memory-hierarchy]]、[[l2-cache]]、[[dvpp]]、[[cube-core]]、[[vector-core]]、[[cv-fusion]]、[[chiplet-uma]]
- 综合：[[ascend-950-spec-table]]、[[ascend-950pr-vs-950dt]]、[[ascend-glossary]]、[[flashattention-optimization]]
- 资料：[[source-ascend-950-npu-whitepaper]]
