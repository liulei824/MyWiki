# sdma

- **类型**: 概念
- **领域**: 昇腾数据搬运
- **首次记录**: 2026-06-23
- **来源数**: 3

## 定义

**SDMA**（System Direct Memory Access）是 [[ascend-950]] 系统级 DMA 引擎，由 [[stars2]] 调度，负责芯片内/芯片间数据拷贝，以及片上内存与 Cache 之间的数据搬运与管理。

## 主要能力

| 能力 | 说明 |
|------|------|
| 芯片内拷贝 | AI Core、片上内存、[[l2-cache]] 等之间 |
| 芯片间拷贝 | 多卡/多 Die 场景数据搬移 |
| Cache 管理 | 通过 **CMO** 操作 L2 Cache 驻留策略 |

## CMO（Cache Maintenance Operations）

SDMA 支持对 [[l2-cache]] 的维护操作（见白皮书 §4.3.2）：

- **Prefetch** — 预取
- **Writeback** — 预写回
- **Invalid** — 无效化
- **Flush** — 冲刷

程序员可配置发生时机与有效范围，配合 **L2 Hint** 优化数据流动。

## 与 NDDMA 的区别

| | **SDMA** | **[[nddma]]** |
|---|----------|---------------|
| 层级 | 系统级，[[stars2]] 调度 | AI Core 内置，Kernel 级 |
| 范围 | 芯片内/间、Memory↔Cache | Global Memory → Vector UB，最多 5 维重排 |
| 典型用途 | 全局数据搬移、L2 CMO | 算子内 Layout 变换、多维 DMA |

## STARS2.0 调度

- 最多并发 **32 个 SDMA 通道**
- 可与 AIC/AIV/[[ccu]]/[[dvpp]] 等任务并发
- AIC/AIV/SDMA 算力切分最多 **16 个资源池**

## 在 PTO 异步通信中的角色（软件视角）

[[pto-comm-isa|PTO 通信 ISA]] 的 `TPUT_ASYNC`/`TGET_ASYNC` 可选 `DmaEngine::SDMA` 后端，做 GM-to-GM 传输：

- AI Core 填 64B `BatchWriteItem` SQE（不经 UB 数据路径，经 MTE staging 写控制结构）。
- **Doorbell 延迟到 Wait**：数据 SQE 发起阶段只写 SQ 内存，`event.Wait()` 时连同 Flag SQE 一起敲门铃。
- 完成同步靠 Flag SQE + 轮询 `SdmaEventRecord`（非零=完成），轮询与 SDMA 传输 wallclock 重叠。
- 默认 block 1MB、最多 48 通道、SQ 深度 2048；`queue_num` 控制多通道条带化。
- A5 上 `TPUT_ASYNC` 回退为 MTE 同步，`TGET_ASYNC` 仍走 SDMA。
- 与 [[urma]] 并列为点对点引擎；集合通信走 [[ccu]]。

## A2/A3 vs A5 SQE 结构差异（跨代迁移）

基于 shmem（A2/A3 AIV 驱动）与 hcomm（A5 AICPU 驱动）源码对比，64B SDMA SQE **不能跨代复用同一结构体**（详见 [[source-sdma-sqe-comparison]]）：

| 差异项 | A2/A3（shmem） | A5（hcomm） | 严重度 |
|--------|----------------|-------------|--------|
| Word4 位域 | ie2 在 bit8；qos/partid/mpam 在 word4 | sssv 紧跟 opcode；qos/partid 移到 word5 | **致命** |
| `length` 位置 | offset 28 | offset 48（`lengthMove`） | **致命** |
| Header `wrCqe` | 未设置（藏在 `res1`） | **= 1**（控制 CQE 回写） | 重要 |
| `kernel_credit` | 240 | 254 | 低 |
| offset 48 | `link_type=255` | 传输长度 | **致命**（互斥） |
| src/dst 地址 | offset 32–47 | offset 32–47 | **相同** |
| Doorbell | AIV MTE 写 `sq_reg_base+8` | AICPU `halSqCqConfig(SQ_TAIL)` | 机制不同 |

> 直接用 shmem SQE 在 A5 上，硬件会在 offset 48 读到 0xFF 而非实际 length。PTO 侧 `BatchWriteItem` 已按代际分 A2/A3 与 A5 布局（见 [[source-pto-comm]] / `comm-async-sdma` raw）。

## 相关

- 概念：[[stars2]]、[[l2-cache]]、[[memory-hierarchy]]、[[nddma]]、[[pto-comm-isa]]、[[urma]]、[[ccu]]、[[pto-backend]]
- 实体：[[ascend-950]]、[[pto-isa]]
- 资料：[[source-ascend-950-npu-whitepaper]]、[[source-pto-comm]]、[[source-sdma-sqe-comparison]]
