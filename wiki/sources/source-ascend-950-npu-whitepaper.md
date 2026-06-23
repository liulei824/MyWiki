# 昇腾950 NPU架构白皮书

- **来源**: `raw/ascend-architecture/昇腾950 NPU架构白皮书.pdf`
- **导入日期**: 2026-06-23
- **类型**: 文档（官方白皮书）
- **作者**: 华为技术有限公司

## 核心要点

- **昇腾950系列**包含 **950PR**（128GB/1.6TB/s 片上内存，偏推荐/Prefill/多模态推理）与 **950DT**（144GB/4TB/s，偏大模型全生命周期训练与推理）
- 基于**第三代达芬奇（DaVinci）架构**，每 AI 子系统含 1 个 Cube Core + 2 个 Vector Core；整芯片 36 个 AI 子系统（规格可冗余裁剪）
- 原生支持 **TF32/FP16/BF16/FP8/MXFP8/HiF8/INT8/MXFP4**；MXFP4 张量算力相对上一代 BF16 最高 **4 倍**
- **Vector Core** 升级为双发射 Register-Based SIMD，首创 **SIMD/SIMT 混合编程**；新增 **NDDMA** 多维 DMA 与 Cube-Vector 高速通路
- **Memory**：128MB 全局 L2 Cache（512B Cache Line、128B Sector、L2 Hint、CMO）；950PR/950DT 片上内存见 [[ascend-950]]
- **互联**：**灵衢 Unified Bus 2.0**，72 Lane HiLink（18×x4 Port，单 Port 最高 4×112Gbps），整芯片 IO 峰值 **2TB/s**；支持 URMA、UB Memory、PCIe 5.0、UBoE
- **STARS2.0** 统一调度 AIC/AIV/CPU/DVPP/SDMA/UB/CCU；**CCU** 硬件卸载集合通信
- **超节点**规模从 384 卡升至 **8192 卡**，整集群可超 **128K 卡**

## 详细摘要

### 背景与定位

白皮书面向 LLM 预训练/后训练/推理、AIGC、推荐、多模态等场景。大模型 All-to-All 通信量相对小模型提升近百倍，KV Cache 存储需求指数增长，单一硬件难以兼顾算存比差异——950 系列在算力密度、存储带宽、互联拓扑三维度升级。

### 芯片物理架构

多 Die 合封：**2×AI Die + 2×IO Die + 8（PR）/4（DT）个高速片上内存模块**，经 D2D Clink 与 Memory Interface 互联，构成 **Chiplet UMA** 统一地址空间。

主要规格（满配）：
- 36 第三代 DaVinci AI 子系统
- 4×AI CPU Cluster（每 Cluster 2×[[linx816]] + 4MB L3）
- 4×DVPP（VPC/JPEGD/JPEGE）
- 128MB 统一 L2 Cache
- [[stars2]] 调度系统

### AI 子系统（第三代 DaVinciCore）

**Cube Core**：支持 HiF8/MXFP8/FP8/MXFP4；更大 L0C Buffer；回写 UB 阶段随路量化与排布转换（FP32→BF16/FP16/FP8，NZ→ND/DN）。

**Vector Core**：FP16/FP32 单核算力较上代 **+100%**；UB 与 Vector ALU 间引入 RegFile；优化 Softmax/GELU 等。

**[[hif8]]**：锥形精度 8bit 格式，38 个阶码表达，不需 MX 缩放因子，动态范围优于 FP8 E4M3。

**[[nddma]]**：最多 5 维重排，Global Memory → UB，内置缓存合并读为 128B。

**[[simd-simt-hybrid]]**：Vector Function（VF）可选 SIMD 或 SIMT 实现；规则 element-wise 走 SIMD，gather/scatter/分支走 SIMT。

**CV 融合**：Cube L1 与 Vector UB 直连，FlashAttention 等算子 Cube-Vector 通路融合，单核性能较上代 **1.5~2×**。

### Memory 子系统

层级含片上内存、L2/L3、AIC/AIV Local Memory（L0A/B/C、L1、UB 各 512KB/64KB/256KB 等）、CPU L1/L2。

L2：跨 Die 一致性由硬件维护；**L2 Hint**（allocate/non-allocate）与 **CMO**（Prefetch/Writeback/Invalid/Flush）由 SDMA 支持。

### 互联与超节点

[[unified-bus]] 2.0：Scale-up/out 端口复用；UB Memory 同步 Load/Store/Atomic，最大 **128TB** Host-Device 及 Device-Device 共享访存；URMA 异步 Jetty 队列（RTP/CTP 传输层）。

[[ccu]] 支持 Broadcast、Reduce Scatter、All Gather、All Reduce、All2All、All2Allv。

[[ascend-super-node]]：UB Switch 组建 K 级超节点；可接超大 CPU 内存池、存储池；UBoE 接入以太网。

### 软件栈

[[cann]] 异构计算架构：加速库、算子编程、编译器、运行时，全面开源开放。

## 关联

- 实体：[[ascend-950]]、[[cann]]、[[linx816]]
- 概念：[[davinci-core-gen3]]、[[unified-bus]]、[[nddma]]、[[stars2]]、[[hif8]]、[[simd-simt-hybrid]]、[[ccu]]、[[ascend-super-node]]

## 与已有知识的关联

- **补充**：本库首篇昇腾架构资料，建立 950 系列硬件知识基线
