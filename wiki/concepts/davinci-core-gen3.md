# davinci-core-gen3

- **类型**: 概念
- **领域**: 昇腾 NPU 架构
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

**第三代达芬奇（DaVinci）架构**是 [[ascend-950]] AI 子系统的计算核心，以 Transformer 为中心，兼顾 LLM、推荐、多模态。

## 核心内容

### 组成

每个 AI 子系统：**1×[[cube-core]]（AIC）+ 2×[[vector-core]]（AIV）**。

### Cube Core

详见 [[cube-core]]：低精度格式、L0C、随路量化、GEMM/FlashAttention 优化。

### Vector Core

详见 [[vector-core]]：双发射 SIMD、[[simd-simt-hybrid]]、RegFile、Softmax/GELU 优化。

### 数据流增强

- [[nddma]] 异步搬运
- [[cv-fusion]] Cube-Vector 内部高速通路
- [[bufferid-sync]] 流水线同步（get_buf/rel_buf）

## 相关

- 实体：[[ascend-950]]
- 概念：[[cube-core]]、[[vector-core]]、[[cv-fusion]]、[[hif8]]、[[nddma]]、[[simd-simt-hybrid]]、[[sdma]]、[[bufferid-sync]]
- 资料：[[source-ascend-950-npu-whitepaper]]
