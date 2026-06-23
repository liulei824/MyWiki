# ascend-950pr-vs-950dt

- **类型**: 综合
- **来源**: [[source-ascend-950-npu-whitepaper]] §3
- **更新**: 2026-06-23

## 一句话

**950PR 偏吞吐型推理（推荐/Prefill），950DT 偏大模型全生命周期（训练+推理），核心差异在片上内存带宽与算力规模。**

## 对比总览

| 维度 | 950PR | 950DT |
|------|-------|-------|
| **定位** | 高性能推荐、LLM Prefill、多模态推理 | 预训练、后训练、推理（Decode+Prefill） |
| **设计目标** | 高吞吐 + 低延迟 | 突破内存墙，覆盖训练与复杂推理 |
| **片上内存** | 最高 **128GB** | 最高 **144GB** |
| **内存带宽** | **1.6TB/s** | **4TB/s**（约 2.5×） |
| **片上内存模块数** | **8** 个 | **4** 个（单模块带宽更高） |
| **Cube Core（满配）** | 32（可裁 28） | 36（可裁 32/28） |
| **Vector Core（满配）** | 64（可裁 56） | 72（可裁 64/56） |
| **MXFP4 总算力（满配）** | 1784 TFLOPS | 2007 TFLOPS |
| **L2 Cache** | 128 / 112 MB | 128 MB |

## 架构共性

两款 **共架构**（见 [[ascend-950]]）：

- 第三代 [[davinci-core-gen3]]
- 128MB 级 [[l2-cache]]、[[memory-hierarchy]] 同一套层次
- [[unified-bus]] 2.0、[[stars2]]、[[ccu]]、[[dvpp]]
- [[linx816]] AI CPU、[[cann]] 软件栈
- Chiplet **2×AI Die + 2×IO Die** + 片上内存，UMA 统一访存

## 选型建议

| 场景 | 推荐 |
|------|------|
| 推荐系统、高 QPS 推理 | **950PR** |
| LLM Prefill、多模态推理 | **950PR** |
| 大模型预训练 / 后训练 | **950DT** |
| Decode + Prefill 混合推理 | **950DT** |
| KV Cache 大、内存带宽敏感 | **950DT**（4TB/s） |

算力与 IO 全表见 [[ascend-950-spec-table]]。

## 相关

- 实体：[[ascend-950]]
- 综合：[[ascend-950-spec-table]]
- 问答：[[2026-06-23-950pr-vs-950dt]]
- 概念：[[memory-hierarchy]]、[[davinci-core-gen3]]
- 资料：[[source-ascend-950-npu-whitepaper]]
