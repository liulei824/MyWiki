# ccu

- **类型**: 概念
- **领域**: 集合通信
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

**CCU**（Collective Communication Unit）是 [[ascend-950]] 上的集合通信硬件加速引擎，实现计算与通信深度并行，减轻 Memory 与 IO 调度压力。

## 核心内容

- 由 [[stars2]] 下发任务；软件通过 CCUM Mission 接口编程
- CCUA 含 MemorySlice 存储与 Reduce Unit 计算
- 支持算法：Broadcast、Reduce Scatter、All Gather、All Reduce、All2All、All2Allv
- 数据搬运可走 [[urma]]（远端 DRAM ↔ 本端 MemorySlice）
- PTO 集合通信 `*_ccu` 测试路径与 CCU 硬件协同 → [[pto-comm-isa]]
- 与 [[unified-bus]] 协同，释放 AI Core 算力

## 相关

- 概念：[[unified-bus]]、[[stars2]]、[[ascend-super-node]]、[[urma]]、[[ub-memory]]、[[pto-comm-isa]]
- 实体：[[ascend-950]]
- 资料：[[source-ascend-950-npu-whitepaper]]
