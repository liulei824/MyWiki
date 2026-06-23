# uboe

- **类型**: 概念
- **领域**: 昇腾互联
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

**UBoE**（UB over Ethernet）是 [[unified-bus]] 协议栈在以太网上的 Scale-Out 实现，可直接利用现有 **Ethernet 交换机**组网，无需专用 UB 交换设备。

## 规格（[[ascend-950]]）

- 整芯片 **2×400Gbps** Ethernet Link（双向合计 **200GB/s**）
- 与 UB Link **静态复用** SerDes：用作 Ethernet 后，UB Link 减少 1 个 400G 端口
- **Port Bifurcation**：1×4 或 2×2 模式
  - 1×400/200/100/50/25 Gbps，或
  - 2×200/100/50/25 Gbps

## 用途

- 昇腾超节点接入已有数据中心以太网络（见 [[ascend-super-node]]）
- [[urma]] 异步能力可基于 Ethernet 物理层与外部互通
- 与 UB Switch 的 UB→Ethernet 转换互补：芯片级 UBoE 可直连标准交换机

## 相关

- 概念：[[unified-bus]]、[[urma]]、[[ascend-super-node]]
- 实体：[[ascend-950]]
- 综合：[[ascend-950-spec-table]]、[[ascend-glossary]]
- 资料：[[source-ascend-950-npu-whitepaper]]
