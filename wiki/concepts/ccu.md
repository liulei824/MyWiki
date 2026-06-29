# ccu

- **类型**: 概念
- **领域**: 集合通信
- **首次记录**: 2026-06-23
- **来源数**: 2

## 定义

**CCU**（Collective Communication Unit）是 [[ascend-950]] 上的集合通信硬件加速引擎，实现计算与通信深度并行，减轻 Memory 与 IO 调度压力。

## 核心内容

- 由 [[stars2]] 下发任务；软件通过 CCUM Mission 接口编程
- CCUA 含 MemorySlice 存储与 Reduce Unit 计算
- 支持算法：Broadcast、Reduce Scatter、All Gather、All Reduce、All2All、All2Allv
- 数据搬运可走 [[urma]]（远端 DRAM ↔ 本端 MemorySlice）
- 与 [[unified-bus]] 协同，释放 AI Core 算力

## 在 PTO 集合通信中的角色（软件视角）

[[pto-comm-isa|PTO 通信 ISA]] 通过 `CollEngine::CCU` 接入 CCU 硬件，加速 `TREDUCE`/`TGATHER`/`TSCATTER`/`TBROADCAST`：

- **不走 `AsyncSession`**——与 [[sdma]]/[[urma]] 的 `DmaEngine` 路径正交；可变参首位为 `CcuTriggerContext`。
- **Host 预编译微码 + 运行时参数化**：`HcclCcuKernelRegister` 把算法翻译为微码，每次 Launch 注入地址/长度/token。
- **Gated 启动**：CCU `WaitEvent(gate)` 阻塞，AIV 一次 **CKE MMIO 写**（`CkeTrigger`）释放 gate，CCU 自主 RDMA 搬运 + MS（SRAM）上 `LocalReduceNb` 规约。
- 当前为 **1D-mesh**，rank 上限 `kMaxReduceRanks = 16`；完成同步靠 Host `aclrtSynchronizeStream(ccuStream)`。
- 底层 RDMA channel（`COMM_PROTOCOL_UBC_CTP`）映射 [[urma]] QP，但应用不直接调 URMA。
- 适用：payload 较大的标准集合；小消息可评估 `CollEngine::AIV` 软件路径。

## 相关

- 概念：[[unified-bus]]、[[stars2]]、[[ascend-super-node]]、[[urma]]、[[ub-memory]]、[[pto-comm-isa]]、[[sdma]]
- 实体：[[ascend-950]]、[[pto-isa]]
- 资料：[[source-ascend-950-npu-whitepaper]]、[[source-pto-comm]]
