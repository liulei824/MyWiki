# cann

- **类型**: 框架
- **首次记录**: 2026-06-23
- **来源数**: 1

## 概述

**CANN**（Compute Architecture for Neural Networks）是华为昇腾 **异构计算架构软件栈**，与 [[ascend-950]] 硬件协同，释放 AI 处理器算力。

## 软件分层

| 层次 | 内容 |
|------|------|
| **高性能加速库** | 预置算子与加速实现 |
| **算子编程体系** | Ascend C 等，面向 [[cube-core]]/[[vector-core]] 开发 |
| **编译器** | 算子编译、图编译 |
| **运行系统** | 任务调度、内存管理、与 [[stars2]] 等硬件协同 |

## 开发者支持

- **全面开源开放**，开放底层能力与代码参考
- 白皮书「更多参考」指向 **《Ascend C 编程指南》**
- 与 [[linx816]] AI CPU 协同：控制类任务、CPU 算子可在 Device 侧执行

## 与硬件映射

| 硬件 | CANN 侧典型对应 |
|------|----------------|
| DaVinci AI Core | Ascend C Kernel、[[nddma]]/[[cv-fusion]] 算子 |
| [[dvpp]] | 媒体预处理 API |
| [[unified-bus]] / [[ccu]] | 集合通信、分布式运行时 |
| [[l2-cache]] Hint/CMO | 算子级 Cache 优化配置 |

## 相关

- 实体：[[ascend-950]]、[[linx816]]
- 概念：[[davinci-core-gen3]]、[[nddma]]、[[cv-fusion]]
- 综合：[[flashattention-optimization]]、[[ascend-glossary]]
- 资料：[[source-ascend-950-npu-whitepaper]]
