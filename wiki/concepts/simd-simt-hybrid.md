# simd-simt-hybrid

- **类型**: 概念
- **领域**: 昇腾编程模型
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

**SIMD/SIMT 混合编程**是 [[davinci-core-gen3]] Vector Core 的新同构编程模型：**以 SIMD 为主、SIMT 为辅**。

## 核心内容

| 模式 | 适用场景 | 特点 |
|------|----------|------|
| **SIMD** | 规则访存、element-wise | 双发 ALU、乱序执行，高吞吐 |
| **SIMT** | Gather/Scatter、复杂分支、HashInsert | 降低不规则控制流开发难度 |

- 基本单元 **Vector Function（VF）**，每个 VF 可选 SIMD 或 SIMT 实现
- 支持 VF 类型间快速切换
- 与 [[cv-fusion]]、Cube-Vector 融合通路协同，提升 FlashAttention 等算子效率

## 相关

- 概念：[[davinci-core-gen3]]、[[nddma]]
- 实体：[[ascend-950]]
- 资料：[[source-ascend-950-npu-whitepaper]]
