# pto-kernel-optimization

- **领域**: PTO-ISA 性能优化实战
- **首次记录**: 2026-06-29
- **来源数**: 1

## 定义

[[pto-isa]] kernel 的组织方式与性能调优方法论。`kernels/` 下多数子目录是自包含小工程（kernel + host + 脚本），各带 `README.md`/`CMakeLists.txt`/`run.sh`，可独立运行。

## 核心内容

### 目录组织

- `kernels/manual/`：手工调优（显式管理 buffer/同步/流水线）——`a2a3/`（gemm_performance、conv2d_forward、topk）、`a5/`（flash_atten、matmul_mxfp4/8_performance）、`common/flash_atten/`。
- `kernels/custom/`：自定义 kernel / operator 扩展脚手架。
- 公共接口在 `include/`，测试在 `tests/`，端到端 demo 在 `demos/`。

### 性能心智模型：按阶段思考

kernel 抽象为流水线：**TLOAD（GM→片上）→ 布局变换（`TEXTRACT`/`TMOV`/`TTRANS`）→ 计算（Cube `TMATMUL` / Vector）→ TSTORE（片上→GM）**。优化目标：最大化稳态重叠 + 降每 FLOP 搬运字节 + 消气泡。

用 profiling 阶段占比读「时间去哪了」：

| 现象 | 解读 | 方向 |
|------|------|------|
| TLOAD≈100% | feed-limited | 减流量/提复用/改重叠 |
| Transform 占主导 | 布局过重 | 减每 FLOP 布局工作 |
| TMATMUL 低、TLOAD 高 | Cube 挨饿、重叠断了 | 修双缓冲/提复用 |

### 可重复调优流程

1. 从正确性开始（CPU 仿真 + 数值检查）→ 2. 固定问题形态（小/中/大 shape）→ 3. 定位瓶颈阶段（profiler 或打点）→ 4. 一次只改一个杠杆 → 5. 锁定稳态（warm-up/drain 不串行化主循环）。

### 四个调优杠杆

1. **并行性（SPMD）**：`block_idx` 切分；两维大优先 2D 划分；GM 访问连续；负载均衡。
2. **Tiling**：放得下片上、满足 buffer 分区；形状匹配引擎（Cube/Vector）；提高算术强度。
3. **数据搬运**：复用（如 GEMM stepK 缓存）、少变换（选对输入布局）、简化输出布局。
4. **重叠与同步**：显式双缓冲 + event/flag，当前 `TMATMUL` 跑时启动下一次 `TLOAD`；只等真实依赖。

### 示例驱动

- GEMM（tiling/stepK/双缓冲）：`kernels/manual/a2a3/gemm_performance/`。
- Flash Attention（分阶段 softmax、tiled QK/PV）：`kernels/manual/common/flash_atten/`。
- 工作区 MegaMoE 实战（PTO 全融合 kernel）：`docs/megamoe/README.md`。

## 相关

- 实体：[[pto-isa]]
- 概念：[[pto-tile]]、[[pto-instruction-set]]、[[pto-backend]]、[[pto-comm-isa]]
- 资料：[[source-pto-isa]]
