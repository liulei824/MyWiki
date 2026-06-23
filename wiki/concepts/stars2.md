# stars2

- **类型**: 概念
- **领域**: 昇腾调度
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

**STARS2.0**（System Task and Resource Scheduler）是 [[ascend-950]] 全芯片任务与资源调度中心，负责 AIC、AIV、CPU、DVPP、SDMA、UB、CCU 等引擎的调度与同步。

## 核心内容

- Host 可下沉 **2048** 条任务流到 Device，降低端到端调度时延
- 通过 **HSCB**（High Speed Control Bus）与 AIC/AIV 交互，调度开销 **ns 级**
- 支持 Group 调度（最多 8 Group，Die 亲和利用 L2 局部性）
- 算力切分：AIC/AIV/SDMA 最多 16 池，其他加速器最多 8 池，可绑定虚拟机
- 并发示例：16 AI CPU 任务、64 Host CPU 任务、64 UB jetty、32 CCU、32 SDMA 通道
- 支持 TOP-DOWN Profiling（任务轨迹、带宽、功耗等）

## 相关

- 实体：[[ascend-950]]、[[linx816]]
- 概念：[[ccu]]、[[unified-bus]]
- 资料：[[source-ascend-950-npu-whitepaper]]
