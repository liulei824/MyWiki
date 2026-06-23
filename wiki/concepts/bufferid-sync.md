# bufferid-sync

- **类型**: 概念
- **领域**: 昇腾算子同步
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

**BufferID 同步**是 [[davinci-core-gen3]] AI Core 新增的流水线同步机制，用类似互斥锁的语义管理核内存储占用与释放。

## API 语义

| 操作 | 类比 | 作用 |
|------|------|------|
| `get_buf()` | 加锁 | 申请/占用 Buffer |
| `rel_buf()` | 解锁 | 释放 Buffer |

## 对比 set_flag / wait_flag

| | BufferID | set_flag / wait_flag |
|---|----------|----------------------|
| 内聚性 | 强，表达存储占用/释放 | 弱，通用 flag |
| 流水线耦合 | 与其他流水线解耦 | 需协调 flag 编号 |
| 编程复杂度 | 更低，更直观 | 较高 |

## 使用场景

- AI Core 内部多阶段 pipeline（Cube → Vector 等）对 L0/L1/UB 的协调
- 与 [[cv-fusion]]、[[nddma]] 配合构建融合算子 pipeline

## 相关

- 概念：[[davinci-core-gen3]]、[[cube-core]]、[[vector-core]]、[[cv-fusion]]
- 实体：[[ascend-950]]
- 资料：[[source-ascend-950-npu-whitepaper]]
