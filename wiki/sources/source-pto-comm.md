# PTO 通信 ISA 与异步后端笔记（SDMA / URMA / CCU）

- **来源**: `raw/pto-isa/comm-isa.md`、`comm-async-sdma.md`、`comm-async-urma.md`、`comm-async-ccu.md`（自写综合，事实源 `code/pto-isa-main/include/pto/comm/`）
- **导入日期**: 2026-06-29
- **类型**: 笔记

## 核心要点

- PTO 通信 ISA 是计算 tile 指令的**通信扩展**，覆盖四类：点对点同步（`TPUT`/`TGET`，经 UB 暂存）、点对点异步（`TPUT_ASYNC`/`TGET_ASYNC`，GM-to-GM DMA + `AsyncEvent`）、信号同步（`TNOTIFY`/`TWAIT`/`TTEST`）、集合通信（`TGATHER`/`TSCATTER`/`TBROADCAST`/`TREDUCE`，基于 `ParallelGroup`）。
- **DmaEngine 选择**：A2/A3 仅 SDMA；A5 的 `TPUT_ASYNC` = SDMA + MTE 回退 + URMA，`TGET_ASYNC` = SDMA + URMA。URMA 仅 A5（NPU_ARCH 3510，CANN ≥ 9.1.0）。
- **SDMA 后端**：AI Core 填 64B `BatchWriteItem` SQE，**doorbell 延迟到 Wait**，靠 Flag SQE + `SdmaEventRecord` 轮询完成；默认 block 1MB、最多 48 通道；多个 MTE3 8 字节写入粒度坑已修复。
- **URMA 后端**：填 `UrmaSqeCtx`+`UrmaSgeCtx` WQE，**PostSend 即敲 doorbell**，轮询 CQ owner 位完成；走 HCCP V2 Jetty + 对称 MR，无需 UB scratch，按 destRankId 建 session。
- **CCU 后端**：集合通信硬件加速，**不走 `AsyncSession`**；Host 预注册微码 + Launch 参数注入，AIV 仅写 CKE gate 触发，CCU 自主 RDMA 搬运 + MS 上规约；当前 1D-mesh，rank ≤ 16。

## 详细摘要

三个异步后端是同一 `pto_comm_inst.hpp` API 下的并列实现路径。SDMA 与 URMA 是**点对点** GM-to-GM 引擎，差异在队列条目格式、doorbell 时机（延迟 vs 立即）、完成同步（Flag SQE vs CQ poll）、是否需要 UB scratch、远端寻址（HCCL `windowsIn[]` vs 对称 MR）。CCU 是**集合通信**引擎，与 SDMA/URMA 的 `DmaEngine` 路径正交，通过 `CollEngine::CCU` 接入，融合搬运与 Reduce。

源码结构（2026-06-29 校正）：实现位于 `include/pto/comm/async/{sdma,urma,ccu}/`，公共会话/事件在 `include/pto/comm/async_common/`，`TPut/TGetAsync` 按架构拆到 `a2a3/`、`a5/`。

## 关联

- 实体：[[pto-isa]]
- 概念：[[pto-comm-isa]]、[[sdma]]、[[urma]]、[[ccu]]、[[unified-bus]]
- 相关摘要：[[source-pto-isa]]、[[source-sdma-sqe-comparison]]

## 与已有知识的关联

- **补充**：在硬件视角的 [[sdma]]、[[urma]]、[[ccu]] 概念页之上，补齐「PTO 软件 ISA 如何驱动这些引擎」的编程模型（SQE/WQE、doorbell、完成同步、session）。
- **矛盾**：无（硬件概念页基于白皮书，本笔记基于 pto-isa 源码，视角互补）。
