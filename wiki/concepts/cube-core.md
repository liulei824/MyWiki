# cube-core

- **类型**: 概念
- **领域**: 昇腾 AI Core
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

**Cube Core（AIC，AI Cube Core）** 是 [[davinci-core-gen3]] 中的张量计算单元，负责 GEMM、FlashAttention 等矩阵类运算。每个 AI 子系统含 **1 个 Cube Core + 2 个 Vector Core**。

## 数值格式

第三代 Cube 新增低精度支持：

| 格式 | 相对 FP16 张量算力（同频率） |
|------|------------------------------|
| HiF8 / MXFP8 / FP8 | **2×** TFLOPS |
| MXFP4 | **4×** TFLOPS |

完整格式：TF32、FP16、BF16、FP8、MXFP8、[[hif8]]、INT8、MXFP4。算力详见 [[ascend-950-spec-table]]。

## 微架构优化

- 更大 **L0C Buffer**（256KB，见 [[memory-hierarchy]]）→ 更灵活 Tiling、更高复用
- 面向 **GEMM / FlashAttention** 优化矩阵运算
- 提升 Cache 复用率

## 随路转换（回写 UB 阶段）

- **量化**：FP32/INT32 → BF16/FP16/FP8/INT8
- **排布**：NZ → ND/DN
- 降低核内缓冲与核间带宽占用，提升端到端吞吐

## 与 Vector 协同

- [[cv-fusion]]：Cube L1 ↔ Vector UB 直连
- 与 [[vector-core]] 融合实现 FlashAttention 等算子，单核性能较上代 **1.5~2×**

## 相关

- 概念：[[davinci-core-gen3]]、[[vector-core]]、[[cv-fusion]]、[[hif8]]、[[memory-hierarchy]]
- 实体：[[ascend-950]]
- 综合：[[ascend-950-spec-table]]
- 资料：[[source-ascend-950-npu-whitepaper]]
