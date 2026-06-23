# PTO-ISA 通信指令编译摘要

- **来源**: `/Users/liulei/cann-code/pto-isa` — `docs/isa/comm/`、`include/pto/comm/`
- **导入日期**: 2026-06-24
- **类型**: 资料摘要（通信专章）

## 权威来源

- 文档：`docs/isa/comm/README_zh.md`
- API：`include/pto/comm/pto_comm_inst.hpp`
- 实现说明：`include/pto/comm/README_zh.md`

## 指令清单

### 同步 P2P
- **TPUT** — GM→UB→GM 远程写；AtomicNone/AtomicAdd；ping-pong
- **TGET** — GM→UB→GM 远程读

### 异步 P2P
- **TPUT_ASYNC** — GM→DMA→GM；`AsyncEvent` + `AsyncSession`
- **TGET_ASYNC** — 同上

| 引擎 | PUT | GET | 平台 |
|------|-----|-----|------|
| SDMA | ✅（1D 连续） | ✅ | A2/A3/A5 |
| URMA | ✅ | ✅ | **A5 / 3510 only** |

### 同步原语
- **TNOTIFY** / **TWAIT** / **TTEST**

### 集合通信
- **TGATHER** / **TSCATTER** / **TBROADCAST** / **TREDUCE**
- A5 CCU 变体测试：`*_ccu` kernel

## 分发与后端

- **a2a3/**：910B/C 原生实现
- **a5/**：950；同步 reuse a2a3；异步扩展 URMA
- **async_common/**：SDMA 公共 + 事件 Wait/Test

## 与 wiki 硬件知识链接

- URMA 异步 → [[urma]]、[[ub-memory]]（硬件 UB 语义）
- SDMA 异步 → [[sdma]]、[[l2-cache]] CMO
- CCU 测试 → [[ccu]]
- A5 平台 → [[ascend-950]]

## 关联

- 概念：[[pto-comm-isa]]
- 实体：[[pto-isa]]
- 资料：[[source-pto-isa-overview]]
