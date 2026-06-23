# pto-isa

- **类型**: 框架
- **首次记录**: 2026-06-24
- **来源数**: 1

## 概述

**PTO（Parallel Tile Operation）** 是昇腾 CANN 定义的 **Tile 级虚拟 ISA**。本仓库（pto-isa）提供 PTO 指令的实现、示例、测试与文档，支持 Ascend **A2/A3/A5** 与 CPU 仿真。

- 远程：https://gitcode.com/cann/pto-isa.git
- 本地镜像：见 [[cann-ecosystem-manifest]]
- 版本：9.1.0（CANN package）

## 定位

- **90+ 条**标准 Tile 指令，桥接不同昇腾代际
- 含**计算/搬运**指令 + **NPU 间通信扩展指令集**
- 集成框架：PyPTO、TileLang Ascend 等
- 与 [[cann]]、[[ascend-950]]（A5）硬件栈协同

## 仓库结构（要点）

| 路径 | 内容 |
|------|------|
| `include/pto/` | 指令 C++ 内建 API |
| `include/pto/comm/` | **通信指令**实现 |
| `docs/isa/` | ISA 逐指令参考 |
| `docs/isa/comm/` | **通信 ISA 文档** |
| `kernels/manual/` | 手工优化 kernel（含 a5 MoE、GEMM+通信） |
| `tests/npu/*/comm/st/` | 通信 ST 测试 |

## 平台

| 代号 | 芯片 |
|------|------|
| a2a3 | Ascend 910B/910C |
| a5 | Ascend 950 |
| CPU SIM | 功能仿真 |

## 相关

- 概念：[[pto-comm-isa]]、[[cann]]、[[urma]]、[[sdma]]、[[ccu]]
- 资料：[[source-pto-isa-overview]]、[[source-pto-isa-comm-isa]]
- 综合：[[ascend-glossary]]
