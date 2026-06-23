# sdma

- **类型**: 概念
- **领域**: 昇腾数据搬运
- **首次记录**: 2026-06-23
- **来源数**: 1

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
- PTO `TPUT_ASYNC`/`TGET_ASYNC` 默认 SDMA 后端 → [[pto-comm-isa]]
- AIC/AIV/SDMA 算力切分最多 **16 个资源池**

## 相关

- 概念：[[stars2]]、[[l2-cache]]、[[memory-hierarchy]]、[[nddma]]、[[pto-comm-isa]]
- 实体：[[ascend-950]]
- 资料：[[source-ascend-950-npu-whitepaper]]
