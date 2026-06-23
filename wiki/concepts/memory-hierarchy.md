# memory-hierarchy

- **类型**: 概念
- **领域**: 昇腾 Memory
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

[[ascend-950]] Memory 子系统缓存 AI 计算的输入、输出与中间结果，层级包括 AI Core Local Memory、[[l2-cache]]、L3、以及高速片上内存（全局 DRAM）。

## 层级结构（由近到远）

```
AI Core Local Memory          ← L0A/B/C、L1 Buffer、Unified Buffer
        ↓
L2 Cache（128MB，服务 AIC/AIV）← [[l2-cache]]
        ↓
高速片上内存（128GB/144GB 级）  ← 950PR/950DT 差异见 [[ascend-950pr-vs-950dt]]
        ↓
L3 Cache（4MB/Cluster，服务 AI CPU）
AI CPU L1/L2
```

## 表4-2 主要容量

| Memory | 大小 |
|--------|------|
| L1 Buffer | **512KB** / AI Core |
| L0A Buffer | **64KB** / AI Core |
| L0B Buffer | **64KB** / AI Core |
| L0C Buffer | **256KB** / AI Core |
| Unified Buffer（UB） | **512KB** / AI Core |
| CPU L1 Cache | **64KB** / CPU Core |
| CPU L2 Cache | **1MB** / CPU Core |
| L3 Cache | **4MB** / CPU Cluster |
| L2 Cache | 最高 **128MB**（芯片级） |
| 950PR 片上内存 | 最高 **128GB**，**1.6TB/s** |
| 950DT 片上内存 | 最高 **96/144GB**，**4TB/s** |

## 职责分工

- **Local Memory（L0/L1/UB）**：单 AI Core 计算过程数据，Cube/Vector 专用
- **L2 Cache**：AIC/AIV 与片上内存间高带宽低延迟缓冲；跨 Die UMA，硬件维护一致性
- **片上内存**：全局性数据 DRAM；950 系列核心差异化资源
- **L3 + CPU Cache**：[[linx816]] 通用计算与控制任务

## 片上内存 RAS

- Online ECC
- 巡检发现薄弱点并回写/隔离
- 预留行动态隔离失效行，用户无感知

## 相关

- 实体：[[ascend-950]]、[[linx816]]
- 概念：[[l2-cache]]、[[nddma]]、[[davinci-core-gen3]]
- 综合：[[ascend-950-spec-table]]、[[ascend-950pr-vs-950dt]]
- 资料：[[source-ascend-950-npu-whitepaper]]
