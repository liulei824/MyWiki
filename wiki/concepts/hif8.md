# hif8

- **类型**: 概念
- **领域**: 低精度数值格式
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

**HiF8** 是 [[davinci-core-gen3]] Cube Core 原生支持的 8bit 浮点格式，兼顾精度与动态范围，无需 MXFP8 的 8bit 缩放因子。

## 核心内容

- **38 个阶码**表达（综合范围约 [-22, 15]），优于 FP8 E4M3 的 18 个指数
- **锥形精度**：靠近 ±1 精度高，远离 ±1 渐降，无跳变
- 变长前缀码点位域 Dot；阶码原码编码；特殊 Subnormal 设计
- 同频率下 HiF8/MXFP8/FP8 可提供 **2×** FP16 张量 TFLOPS；MXFP4 为 **4×**

## 相关

- 概念：[[davinci-core-gen3]]
- 实体：[[ascend-950]]
- 资料：[[source-ascend-950-npu-whitepaper]]
