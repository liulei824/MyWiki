# A2/A3 vs A5 SDMA SQE 结构对比

- **来源**: `raw/sdma/a23_vs_a5_sdma_sqe_comparison.md`（基于 shmem AIV 驱动 vs hcomm AICPU 实际代码）
- **导入日期**: 2026-06-29
- **类型**: 笔记

## 核心要点

- A2/A3（shmem `stars_sdma_sqe_t`）与 A5（hcomm `Rt91095StarsMemcpySqe`）的 64B SQE **布局完全不同**，不能复用同一结构体跨代。
- **致命差异**：Word4 位域排列不同（即使 sssv/dssv/sns/dns 逻辑值相同，二进制也不同）；`length` 从 offset 28（A2/A3）移到 offset 48（A5 `lengthMove`）；A5 header 须设 **`wrCqe=1`**。
- **次要但重要**：qos/partid/mpam 从 word4 移到 word5（`mapamPartId`）；word5/6/7 语义变化（src/dst stream id 位置）；`kernel_credit` 240→254。
- 若直接用 shmem SQE 在 A5 上，硬件在 offset 48 读 length 会得到 `link_type=255`（0xFF），而非实际传输长度。
- src/dst 地址（offset 32–47）两代位置相同；doorbell 机制 A2/A3 为 AIV MTE 写 `sq_reg_base+8`，A5 hcomm 用 `halSqCqConfig(SQ_TAIL)`（AICPU 已验证）。
- 迁移最小方案：按平台 `#ifdef` 切换 SQE 结构体与填充函数，保留 SQ buffer 写入、cache 刷新、tail 管理逻辑。

## 详细摘要

对比基于 shmem `aclshmemi_fill_sdma_sqe()`（AIV，A2/A3 已验证）与 hcomm `BuildA5SqeSdmaCopy()`（AICPU，A5 已验证）。Header 上 A5 展开 lock/unlock/ie/preP/postP/**wrCqe** 等控制位，shmem 的 `stars_sdma_sqe_t` 把这些位藏在 `res1` 里未设 wrCqe。

Word4 是最大结构性差异：A2/A3 把 ie2 放在 bit8、qos/partid/mpam 在 word4；A5 把 sssv 紧跟 opcode（bit8）、新增 stride/compEn，qos/partid 移到 word5。完整 64 字节布局对照见 raw 原文 §8。

Doorbell：shmem 用 `DataCacheCleanAndInvalid` 刷全量 cache 后 MTE 写 doorbell；hcomm 用 `dsb st` + HAL。AIV 侧 MTE 写 `sq_reg_base+8` 在 A5 上是否仍有效待验证。

## 关联

- 实体：[[ascend-950]]、[[pto-isa]]
- 概念：[[sdma]]、[[pto-comm-isa]]、[[pto-backend]]、[[stars2]]
- 相关摘要：[[source-pto-comm]]
- 代码参考：`code/reference/shmem/`（A2/A3）、`code/reference/hcomm/`（A5）

## 与已有知识的关联

- **补充**：[[sdma]] 白皮书视角之上，补齐 A2/A3↔A5 的 SQE 二进制级差异；与 [[source-pto-comm]] 中 PTO SDMA 后端（`BatchWriteItem`、doorbell 延迟到 Wait）形成「PTO 实现 vs shmem/hcomm 原生驱动」的对照。
- **矛盾**：无。
