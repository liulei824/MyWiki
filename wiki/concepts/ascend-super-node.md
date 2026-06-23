# ascend-super-node

- **类型**: 概念
- **领域**: 昇腾集群
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

**昇腾超节点（Super Node）** 是基于 [[unified-bus]] 互联的多卡集群单元，[[ascend-950]] 上超节点规模从上一代 **384 卡** 升至 **8192 卡**，整集群可超 **128K 卡**。

## 核心内容

- 搭配 UB Switch 组建 K 级超节点；拓扑含 Full Mesh、Clos、混合组网
- **超大内存池**：Rack/Pod 经 UB 直接访问 CPU 大内存池，高带宽低延迟
- **超大存储池**：经 UB 直接访问，无中间存储协议转换
- **以太互通**：UB Switch UB→Ethernet 转换，或芯片 **UBoE** 直连接入标准以太交换机

## 相关

- 实体：[[ascend-950]]
- 概念：[[unified-bus]]、[[ccu]]
- 资料：[[source-ascend-950-npu-whitepaper]]
