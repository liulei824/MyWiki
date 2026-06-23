# l2-cache

- **类型**: 概念
- **领域**: 昇腾 Memory
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

[[ascend-950]] 配置最高 **128MB** 统一 **L2 Cache**，主要服务 AIC/AIV（[[davinci-core-gen3]]），在重复访问场景下避免频繁访问片上内存。

## 架构特性

1. **[[chiplet-uma]]**：2 Die 统一地址空间，可跨 Die 访问 L2，具局部亲和性
2. **一致性**：硬件维护双 Die 间 L2 一致性，软件无感
3. **微架构**
   - 多 Bank 分布式，512B 低位交织（高位异或交织）
   - Cache Line **512B**，支持 **128B Sector Cache**（128B/256B 访问更高效）
   - 每 Bank 支持同时读写
4. **容量**：950PR 128/112 MB；950DT **128 MB**（见 [[ascend-950-spec-table]]）

## L2 Hint 策略

程序员在用例中配置 hint，硬件据此做 allocate / victim 决策：

- **allocate**：下一 Task 输入数据 → 缓存在 L2，提高复用
- **non-allocate**：短期不用数据 →  bypass L2 直写 Global Memory，避免污染工作集

典型场景：Task0 输出 data B 为 Task1 输入 → 缓存；data A 不再使用 → non-allocate。

## CMO（Cache Maintenance Operations）

通过 [[stars2]] 调度的 **[[sdma]]** 实现 L2 驻留策略：

| 操作 | 作用 |
|------|------|
| Prefetch | 预取 |
| Writeback | 预写回 |
| Invalid | 无效化 |
| Flush | 冲刷 |

可配置发生时机与有效范围。

## 与调度的关系

[[stars2]] **Group 调度**（最多 8 Group）支持按 Die 亲和调度 AI Core，更好利用 L2 局部性。

## 性能

离散小包与随机访存场景，同带宽条件下较上一代性能 **2 倍以上**（白皮书 §3）。

## 相关

- 概念：[[memory-hierarchy]]、[[chiplet-uma]]、[[davinci-core-gen3]]、[[stars2]]、[[sdma]]
- 实体：[[ascend-950]]
- 综合：[[ascend-950-spec-table]]
- 资料：[[source-ascend-950-npu-whitepaper]]
