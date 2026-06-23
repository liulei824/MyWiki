# chiplet-uma

- **类型**: 概念
- **领域**: 昇腾芯片物理架构
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

[[ascend-950]] 采用 **Chiplet 多 Die 合封 + UMA（Unified Memory Access）** 架构：多个 Die 与片上内存模块通过高速互联组成统一地址空间，所有处理器共享物理内存池、访问延迟一致。

## Die 组成

| 组件 | 数量 | 说明 |
|------|------|------|
| **AI Die** | 2 | 计算 Die，含 DaVinci AI Core |
| **IO Die** | 2 | IO 通信 Die，含 UB/PCIe 等 |
| **片上内存模块** | PR **8** / DT **4** | 高速 DRAM，容量/带宽见 [[ascend-950pr-vs-950dt]] |

互联：**D2D Clink** + Memory Interface。

## UMA 特性

- 整芯片地址空间**统一管理**
- 可跨 Die 访问 [[l2-cache]]，具**局部亲和性**
- 双 Die 间 L2 **一致性由硬件维护**，软件无感
- [[stars2]] Group 调度可按 Die 亲和分配 AI Core，优化 L2 局部性

## 相关

- 实体：[[ascend-950]]
- 概念：[[l2-cache]]、[[memory-hierarchy]]、[[stars2]]
- 综合：[[ascend-950pr-vs-950dt]]、[[ascend-glossary]]
- 资料：[[source-ascend-950-npu-whitepaper]]
