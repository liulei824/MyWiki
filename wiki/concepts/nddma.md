# nddma

- **类型**: 概念
- **领域**: 昇腾算子/数据搬运
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

**NDDMA**（N-dimensional Direct Memory Access Engine）是 [[davinci-core-gen3]] AI Core 内置的多维 DMA 引擎，支持多维 Layout 搬运与变换。

## 核心内容

- 最多 **5 维**数据重排，Global Memory → Vector Core **Unified Buffer（UB）**
- 可合并数据搬运 + 重排/转置，简化 Kernel 编程（NCHW/NHWC 等）
- 地址生成逻辑硬化；内置缓存发掘局部性，合并为 **128B** 读操作

## 相关

- 概念：[[davinci-core-gen3]]、[[simd-simt-hybrid]]
- 实体：[[ascend-950]]
- 资料：[[source-ascend-950-npu-whitepaper]]
