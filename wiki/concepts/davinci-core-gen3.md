# davinci-core-gen3

- **类型**: 概念
- **领域**: 昇腾 NPU 架构
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

**第三代达芬奇（DaVinci）架构**是 [[ascend-950]] AI 子系统的计算核心，以 Transformer 为中心，兼顾 LLM、推荐、多模态。

## 核心内容

### 组成

每个 AI 子系统：**1×Cube Core（AIC）+ 2×Vector Core（AIV）**。

### Cube Core

- 低精度：HiF8、MXFP8、FP8、MXFP4
- MXFP4 峰值算力可达上一代 BF16 的 **4 倍**
- 更大 L0C；GEMM/FlashAttention 优化；随路量化与排布转换

### Vector Core

- 双发射 Register-Based SIMD；[[simd-simt-hybrid]]
- FP16/FP32 单核算力 **+100%**；原生 BF16；Softmax/GELU 微架构优化
- RegFile 介于 UB 与 Vector ALU 之间

### 数据流增强

- [[nddma]] 异步搬运
- Cube-Vector 内部高速通路（[[source-ascend-950-npu-whitepaper]] 中 CV 融合）
- BufferID 同步机制（类 mutex，简化流水线）

## 相关

- 实体：[[ascend-950]]
- 概念：[[hif8]]、[[nddma]]、[[simd-simt-hybrid]]
- 资料：[[source-ascend-950-npu-whitepaper]]
