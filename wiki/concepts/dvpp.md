# dvpp

- **类型**: 概念
- **领域**: 昇腾多媒体
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

**DVPP**（DaVinci Vision Pre-Processing）是 [[ascend-950]] 图像/视频预处理子系统，硬件完成解码、预处理、编码，避免占用 AI Core / AI CPU。

## 组成模块

| 模块 | 全称 | 功能 |
|------|------|------|
| **JPEGD** | JPEG Decoder | JPEG 比特流 → YUV 帧 |
| **JPEGE** | JPEG Encoder | 原始帧/VPC 输出 → JPEG 比特流 |
| **VPC** | Vision Processing Core | 图像预处理 → AIC 可用格式 |

芯片集成：**4×VPC、4×JPEGE、8×JPEGD**（满配，规格见 [[ascend-950-spec-table]]）。

## VPC 能力

对标 OpenCV、TensorFlow、TorchVision、Pillow、DALI：

- 尺度：Resize、Crop、Padding
- 采样：UVDEC（上采样）、UVUP（下采样）
- 色彩：CSC、HSV、PixAug
- 几何：Affine、Perspective
- 多路 1080p 并行；支持 [[stars2]] 直接硬件调度

## JPEGD 规格

- 最大分辨率：**32768 × 32768**
- 格式：YUV444/422/420/440/400（8bit），baseline JPEG 输入，semi-planar 输出
- 支持区域解码；对标 libjpeg-turbo v2.0.2
- 满配：**4096 FPS@1080P**

## JPEGE 规格

- 最大分辨率：**32768 × 32768**
- Baseline DCT 编码；YUV420 semi-planar、YUV422 packed、YUV444 planar/packed 等
- 满配：**1024 FPS@1080P**（4 Core）或 512 FPS（2 Core）

## 典型场景

AI 训练数据加载、推理前处理、视频分析、多媒体 pipeline——JPEG 解码/预处理瓶颈由 DVPP 硬件卸载。

## 相关

- 实体：[[ascend-950]]
- 概念：[[stars2]]、[[davinci-core-gen3]]
- 综合：[[ascend-950-spec-table]]
- 资料：[[source-ascend-950-npu-whitepaper]]
