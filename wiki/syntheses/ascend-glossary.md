# ascend-glossary

- **类型**: 综合
- **来源**: [[source-ascend-950-npu-whitepaper]] 表1-1 关键术语
- **更新**: 2026-06-23

## 说明

昇腾950 白皮书关键术语速查。已有专页的术语链到 wiki 页面；其余保留原文定义。

## AI Core 与计算

| 术语 | 定义 | Wiki |
|------|------|------|
| **AIC** | AI Cube Core，AI Core 组合中的张量核 | [[cube-core]] |
| **AIV** | AI Vector Core，AI Core 组合中的向量核 | [[vector-core]] |
| **AI CPU** | 芯片内自研 ARM CPU，950 上为 [[linx816]] | [[linx816]] |
| **NDDMA** | AI Core 内置多维 DMA，支持 Layout 搬运变换 | [[nddma]] |
| **SIMD** | 单指令多数据并行 | [[simd-simt-hybrid]] |
| **SIMT** | 单指令多线程并行 | [[simd-simt-hybrid]] |
| **UB（Unified Buffer）** | AI Core 内部存储，主要用于矢量计算（512KB/Core） | [[memory-hierarchy]] |

## 软件与调度

| 术语 | 定义 | Wiki |
|------|------|------|
| **CANN** | Compute Architecture for Neural Networks，昇腾异构计算软件栈 | [[cann]] |
| **STARS** | System Task and Resource Scheduler，全芯片任务资源调度 | [[stars2]] |
| **HSCB** | High Speed Control Bus，STARS 与 AIC/AIV 交互的高速调度总线 | [[stars2]] |
| **DVPP** | DaVinci Vision Pre-Processing，图像编解码与预处理 | [[dvpp]] |

## 互联与通信

| 术语 | 定义 | Wiki |
|------|------|------|
| **UB（Unified Bus）** | 灵衢总线，统一互联标准协议 | [[unified-bus]] |
| **URMA** | UB Remote Memory Access，异步内存拷贝语义 | [[urma]] |
| **UB Memory** | UB 同步访存语义，Load/Store/Atomic | [[ub-memory]] |
| **UBoE** | UB over Ethernet，UB 对接以太网 | [[uboe]] |
| **RTP** | Reliable Transport，UB 可靠传输层（4 Port） | [[urma]] |
| **CTP** | Compact Transport，UB 轻量传输层（9 Port） | [[urma]] |
| **CCU** | Collective Communication Unit，集合通信加速 | [[ccu]] |
| **Clos** | 多级交换无阻塞网络拓扑 | [[unified-bus]]、[[ascend-super-node]] |

## Memory 与 Cache

| 术语 | 定义 | Wiki |
|------|------|------|
| **UMA** | Unified Memory Access，共享物理内存池、统一访问延迟 | [[chiplet-uma]] |
| **CMO** | Cache Maintenance Operations，[[sdma]] 实现的 L2 管理 | [[l2-cache]] |
| **SDMA** | System DMA，芯片内/间拷贝及 Cache 管理 | [[sdma]] |
| **Sector Cache** | 缓存分 Sector 策略，512B Line 含 4×128B Sector | [[l2-cache]] |
| **NCA** | Non-Cacheable Allocate，强制 Cacheable→Non-Cacheable |

## 芯片物理

| 术语 | 定义 | Wiki |
|------|------|------|
| **Die** | 芯片晶粒 | [[chiplet-uma]] |
| **AI Die** | 950 PR/DT 中的计算 Die | [[chiplet-uma]] |
| **IO Die** | 950 PR/DT 中的 IO 通信 Die | [[chiplet-uma]] |
| **Host** | Host-Device 架构主机侧（x86/鲲鹏 CPU） | — |
| **Device** | Host-Device 架构设备侧（950 NPU） | [[ascend-950]] |

## 应用与通用

| 术语 | 定义 |
|------|------|
| **LLM** | Large Language Model，大语言模型 |
| **AIGC** | AI Generated Content，AI 生成内容 |

## 相关

- 实体：[[ascend-950]]
- 资料：[[source-ascend-950-npu-whitepaper]]
