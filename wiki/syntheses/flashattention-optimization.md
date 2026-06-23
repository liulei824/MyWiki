# flashattention-optimization

- **类型**: 综合
- **来源**: [[source-ascend-950-npu-whitepaper]] §3、§4.1
- **更新**: 2026-06-23

## 背景

FlashAttention 是 LLM 关键算子，Cube（矩阵乘）与 Vector（Softmax/mask）交替执行，易受带宽与 Vector 算力制约。

## 950 硬件优化点

### 1. [[cv-fusion]] 核内通路

- [[cube-core]] L1 ↔ [[vector-core]] UB 直连
- 减少 [[l2-cache]] 与 Global Memory 往返
- 传输支持随路精度与排布转换

### 2. Vector 算力翻倍

- FP16/FP32 单核 **+100%**，Softmax 等不再成瓶颈

### 3. Cube 低精度与微架构

- [[hif8]] / MXFP8 / FP8 / MXFP4 支持
- 更大 L0C、GEMM 优化

### 4. 性能提升

- 单核 FlashAttention 较上一代 **1.5~2×**
- 结合 MXFP8/MXFP4 与计算通信并行（[[ccu]]、[[stars2]]）

## 开发关联

- 数据搬运：[[nddma]]（Layout 变换）
- 流水线同步：[[bufferid-sync]]
- 编程模型：[[simd-simt-hybrid]]（Vector 部分）

## 相关

- 概念：[[cv-fusion]]、[[cube-core]]、[[vector-core]]、[[hif8]]、[[nddma]]、[[bufferid-sync]]
- 实体：[[ascend-950]]
- 资料：[[source-ascend-950-npu-whitepaper]]
