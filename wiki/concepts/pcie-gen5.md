# pcie-gen5

- **类型**: 概念
- **领域**: 昇腾 IO
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

[[ascend-950]] 集成 **PCIe 5.0** 控制器，与 [[unified-bus]] 端口**静态复用** SerDes，提供标准 PCIe 主机/设备互联能力。

## 规格

| 项目 | 规格 |
|------|------|
| 协议 | PCIe **GEN5**，向下兼容 GEN4/3/2/1 |
| 模式 | **1×16** / x8 / x4 / x2 Link |
| 带宽 | **128GB/s 双向**（x16） |
| 工作模式 | **EP** 或 **RC**，静态选择 |
| 端口复用 | 与 UB 共用 **4 个 Port** |
| 加速器 | 支持 DMA、MCTP |

## 与 UB 的关系

- PCIe 与 UB/UBoE 共享物理 SerDes，规划组网时需考虑端口分配
- Host（x86/鲲鹏）经 PCIe 与 Device（950 NPU）通信的经典 Host-Device 路径

## 相关

- 概念：[[unified-bus]]、[[uboe]]
- 实体：[[ascend-950]]
- 综合：[[ascend-950-spec-table]]、[[ascend-glossary]]
- 资料：[[source-ascend-950-npu-whitepaper]]
