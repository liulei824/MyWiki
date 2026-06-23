# linx816

- **类型**: 硬件
- **首次记录**: 2026-06-23
- **来源数**: 1

## 概述

华为自研 **Linx816** 是昇腾950 AI CPU 子系统使用的 ARM 架构 CPU 核心（ARMv8-A），支持物理双线程。

## 关键事实

- 每核可配置双线程或单线程；两线程共享 L1/L2
- 支持 NEON；与 AI Core 共享统一片上内存
- 通过硬件全局缓存一致性与 AI Core + L2 交换数据
- [[ascend-950]] 集成 4 个 AI CPU Cluster，每 Cluster 2×Linx816 + 4MB L3 Cache

## 职责

- **控制类**：NPU 侧 OS、页表、性能监控、算子编译、加速器/IO 调度
- **计算类**：CPU 算子（控制、标量、向量等），补充 AI Core

## 相关

- 实体：[[ascend-950]]、[[cann]]
- 资料：[[source-ascend-950-npu-whitepaper]]
