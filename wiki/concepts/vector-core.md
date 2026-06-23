# vector-core

- **类型**: 概念
- **领域**: 昇腾 AI Core
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

**Vector Core（AIV，AI Vector Core）** 是 [[davinci-core-gen3]] 中的向量计算单元，负责 Softmax、GELU、element-wise 等非矩阵类运算。每个 AI 子系统含 **2 个 Vector Core**。

## 算力

- 单核 **FP16 / FP32** TFLOPS 较上代 **+100%**
- 使 Cube-Vector 融合算子（如 FlashAttention）的非矩阵部分不再成瓶颈
- 满配 Vector 算力见 [[ascend-950-spec-table]]

## 指令与格式

- 原生 **BF16** 支持
- 扩展浮点格式转换指令，强化量化/反量化
- 支持 FP32、FP16、BF16、INT8/16/32/64 等

## 微架构

- **双发射 Register-Based SIMD** 新架构
- [[simd-simt-hybrid]]：SIMD 为主、SIMT 为辅
- 针对 **Softmax、GELU** 等关键函数优化
- 提升张量 ALU 利用率，减少数据依赖「气泡」
- 保持低指令延迟

## 内存架构

- **Unified Buffer（512KB）** 与 Vector ALU 之间引入 **RegFile** 寄存器
- 更高带宽与数据复用
- 数据搬运可经 [[nddma]] 从 Global Memory 写入 UB

## 与 Cube 协同

- [[cv-fusion]] 内部通路实现 Cube 矩阵 + Vector 向量高效融合
- 见 [[cube-core]]

## 相关

- 概念：[[davinci-core-gen3]]、[[cube-core]]、[[cv-fusion]]、[[simd-simt-hybrid]]、[[nddma]]
- 实体：[[ascend-950]]
- 综合：[[ascend-950-spec-table]]
- 资料：[[source-ascend-950-npu-whitepaper]]
