# ub-memory

- **类型**: 概念
- **领域**: 昇腾互联
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

**UB Memory** 是 [[unified-bus]] 2.0 提供的**同步访存**语义：Core（AI Core / AI CPU）可直接对远端芯片内存发起 Load / Store / Atomic，如同访问本地内存。

## 交互流程

1. Core 发起同步操作 → UB
2. UB Memory Decoder 解析目的节点与地址
3. 经底层 Port 送至对端芯片
4. 对端 **UMMU** 做地址翻译与权限校验后直接访问内存

## 支持操作

- **Write**
- **Read**
- **AtomicStore**
- **AtomicLoad**
- **AtomicSwap**
- **AtomicCompareAndSwap**

## 规模与用途

- 最大 **128TB** Host-Device 及 Device-Device **共享访存**（白皮书 §3）
- 与 [[urma]] 异步语义互补：同步适合细粒度共享内存编程，异步适合 bulk 搬运与消息

## 在 UB 协议栈中的位置

| 语义 | 机制 | 编程模型 |
|------|------|----------|
| 同步 | **UB Memory**（本页） | Load/Store/Atomic |
| 异步 | [[urma]] | Jetty 队列 |
| 集合通信 | [[ccu]] | Mission 任务 |

## 相关

- 概念：[[unified-bus]]、[[urma]]、[[ccu]]、[[ascend-super-node]]
- 实体：[[ascend-950]]
- 综合：[[ascend-950-spec-table]]
- 资料：[[source-ascend-950-npu-whitepaper]]
