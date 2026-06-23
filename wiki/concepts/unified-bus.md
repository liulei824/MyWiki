# unified-bus

- **类型**: 概念
- **领域**: 昇腾互联
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

**灵衢（Unified Bus，UB）** 是华为统一的互联标准协议，[[ascend-950]] 搭载 **UB 2.0**，支持计算原生内存语义、IO 语义与网络通信语义。

## 核心内容

### 带宽与端口

- 18×x4 Port，每 Port 最高 112Gbps；UB 双向带宽 **2016GB/s**
- Scale-up（芯片间）与 Scale-out（节点间）端口可复用
- 兼容 **PCIe 5.0 x16**（128GB/s 双向）、**UBoE**（2×400Gbps 接以太网）

### 编程语义

| 语义 | 机制 | 用途 |
|------|------|------|
| 同步 | **UB Memory** | Load/Store/Atomic，最大 128TB 共享访存 |
| 异步 | **URMA** | Jetty 队列，Write/Read/Send/Atomic 等 |
| 集合通信 | **[[ccu]]** | 硬件卸载 AllReduce 等 |

### 组网

- 拓扑：nD-Mesh、Clos、Full Mesh+Clos 混合
- 最大 **8192 卡**超节点；整集群 **>128K 卡**
- UB On Chip Switch：IO Die 内 9×x4 Port 转发，不占计算 Die/DRAM 带宽

## 相关

- 实体：[[ascend-950]]
- 概念：[[ccu]]、[[ascend-super-node]]
- 资料：[[source-ascend-950-npu-whitepaper]]
