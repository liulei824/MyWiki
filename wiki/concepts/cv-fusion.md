# cv-fusion

- **类型**: 概念
- **领域**: 昇腾算子融合
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

**CV 融合（Cube-Vector Fusion）** 是 [[davinci-core-gen3]] 中 [[cube-core]] 与 [[vector-core]] 之间的高效数据通路，实现矩阵计算与向量计算在核内融合，减少 [[l2-cache]] 层数据交换。

## 硬件通路

- **Cube L1 Buffer** ↔ **Vector Unified Buffer** 直接 CV 数据传递通道
- 提高核内数据复用率，降低 L2 流量
- 传输过程支持**随路数值精度转换**与**数据排布转换**

## 典型算子：FlashAttention

针对 FlashAttention 带宽瓶颈：

- Cube 负责矩阵乘（QK、PV 等）
- Vector 负责 Softmax、mask 等向量操作
- 核内通路融合，避免频繁写回 Global Memory
- 结合 MXFP8/MXFP4 等低精度，单核性能较上代 **1.5~2×**

## 随路转换能力

Cube → Vector 传输时可同时完成：

- 精度：FP32 → BF16/FP16/FP8 等
- 排布：NZ → ND/DN 等

与 [[cube-core]] 回写 UB 阶段的随路量化策略一致，提升端到端吞吐与能效。

## 编程意义

- 简化 Cube/Vector 间数据流转，降低融合算子开发复杂度
- 与 [[nddma]]、[[bufferid-sync]] 配合构建融合算子 pipeline

## 相关

- 概念：[[davinci-core-gen3]]、[[cube-core]]、[[vector-core]]、[[l2-cache]]、[[hif8]]、[[nddma]]、[[bufferid-sync]]
- 综合：[[flashattention-optimization]]
- 实体：[[ascend-950]]
- 资料：[[source-ascend-950-npu-whitepaper]]
