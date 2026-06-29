# urma

- **类型**: 概念
- **领域**: 昇腾互联
- **首次记录**: 2026-06-23
- **来源数**: 2

## 定义

**URMA**（UB Remote Memory Access）是 [[unified-bus]] 2.0 提供的**异步内存访问**语义，Core（AI Core / AI CPU / [[stars2]]）通过 Jetty 队列与远端节点通信。

## 交互流程

1. Core 通过 **Doorbell** 调用 URMA Jetty 队列
2. 底层 Port 与远端节点通信
3. **UMMU** 提供 VA→PA 转换与权限控制

## 通信能力（Jetty 队列）

- Write、Write with ImmediateData、Write with Notify
- Read
- Send、Send with ImmediateData
- Atomic FetchAdd、CompareAndSwap

## 传输层模式

| 模式 | 全称 | 特点 | Port 带宽 |
|------|------|------|-----------|
| **RTP** | Reliable Transport | 端到端可靠传输，可重传；多 Transport Channel 多路径 | **4** Port |
| **CTP** | Compact Transport | 轻量传输，无端到端可靠重传 | **9** Port |

RTP 适合可靠性要求高的场景；CTP 适合追求带宽与低开销的场景。

## 与 UBoE 的关系

URMA 异步能力可基于 **Ethernet 物理层**与外部互通（见 [[unified-bus]] UBoE）。

[[ccu]] 集合通信中的数据搬运可调用 URMA 完成远端 DRAM ↔ 本端 MemorySlice 搬移。

## 在 PTO 异步通信中的角色（软件视角）

[[pto-comm-isa|PTO 通信 ISA]] 的 `TPUT_ASYNC`/`TGET_ASYNC` 可选 `DmaEngine::URMA` 后端（**仅 A5 / NPU_ARCH 3510，CANN ≥ 9.1.0**）：

- AI Core 填 `UrmaSqeCtx`(48B)+`UrmaSgeCtx`(16B) WQE，用 `ld_dev`/`st_dev` 直驱，**无需 UB scratch**。
- **PostSend 即敲 doorbell**（与 [[sdma]] 延迟到 Wait 不同），硬件立即拉取 WQE。
- 完成同步靠**轮询 CQ**（`UrmaJfcCqeCtx` owner 位翻转），非 Flag SQE。
- 走 HCCP V2 / Jetty + 对称 MR（`UrmaMemInfo.addr` + token/EID），按 `destRankId` 建 session（一个 peer 一条上下文）。
- `AsyncEvent.handle = (destRankId<<32) | curHead`；当前 `qpNum=1`。
- 与 [[sdma]] 并列为点对点引擎；集合通信走 [[ccu]]。

## 相关

- 概念：[[unified-bus]]、[[ub-memory]]、[[ccu]]、[[stars2]]、[[pto-comm-isa]]、[[sdma]]
- 实体：[[ascend-950]]、[[pto-isa]]
- 综合：[[ascend-950-spec-table]]
- 资料：[[source-ascend-950-npu-whitepaper]]、[[source-pto-comm]]
