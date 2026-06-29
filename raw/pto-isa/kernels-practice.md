# PTO Kernels 组织与性能优化实战

- **来源**: `code/pto-isa-main` — `kernels/README_zh.md`、`docs/coding/opt_zh.md`
- **整理日期**: 2026-06-29
- **类型**: 自写综合笔记（基于官方仓库文档）

## 一、kernels 目录组织

`kernels/` 下多数子目录是**自包含小工程**（kernel + host + 脚本），各带 `README.md` / `CMakeLists.txt` / `run.sh`，可独立运行。

```
kernels/
├── manual/                 # 手工调优 kernel（显式管理 buffer/同步/流水线，偏 NPU）
│   ├── a2a3/               # A2/A3 平台
│   │   ├── gemm_performance/   # 高性能 GEMM 示例（tiling / stepK 缓存 / 双缓冲）
│   │   ├── conv2d_forward/     # Conv2D 前向
│   │   └── topk/              # TopK
│   ├── a5/                 # A5 平台
│   │   ├── flash_atten/        # A5 Flash-Attention
│   │   ├── matmul_mxfp4_performance/   # MXFP4 矩阵乘
│   │   └── matmul_mxfp8_performance/   # MXFP8 矩阵乘
│   └── common/             # 跨平台
│       └── flash_atten/       # Flash-Attention（A2/A3/A5）
└── custom/                 # 自定义 kernel / operator 扩展脚手架
```

- 公共接口在 `include/`；测试在 `tests/`；端到端 demo（含 CPU）在 `demos/`。
- 新增 kernel 建议配套简短 `README.md` + `run.sh`，便于统一发现/运行。

## 二、性能心智模型：按阶段思考

多数高性能 kernel 抽象为一条阶段流水线：

1. **TLOAD**：GM → 片上（Mat/Vec tiles）
2. **布局/暂存变换**：`TEXTRACT` / `TMOV` / `TTRANS` / `TRESHAPE`
3. **计算**：Cube（`TMATMUL` / `TMATMUL_ACC`）或 Vector（逐元素 / 归约 / exp/log / cmp/sel）
4. **TSTORE**：片上 → GM

优化目标：**最大化稳态重叠** + **降低每 FLOP 搬运字节** + **避免流水线气泡**。

### 用 profiling 阶段占比读「时间去哪了」

| 现象 | 解读 | 处理方向 |
|------|------|----------|
| TLOAD 接近 100% | 流水线喂不饱（feed-limited） | 减流量 / 提升复用 / 改重叠 |
| Transform（TEXTRACT/TMOV）占主导 | 布局工作过重 | 减少每 FLOP 的布局工作，或摊薄 |
| TMATMUL 很低、TLOAD 很高 | Cube 挨饿，重叠断了或带宽饱和 | 修双缓冲 / 提升复用 |

## 三、可重复的调优流程

1. **从正确性开始**：先 CPU 仿真 `python3 tests/run_cpu.py --verbose`，尽早加数值检查（max/relative diff）
2. **固定问题形态**：选代表性 shape（含小/中/大），结果记入 kernel README 表格便于回归
3. **定位瓶颈阶段**：用 profiler 阶段占比；无 profiler 则在 load/compute/store 打点
4. **一次只改一个杠杆**：只改 tiling，或只改核划分，或只改重叠策略
5. **锁定稳态**：确保 warm-up / drain 不把主循环串行化

## 四、四个调优杠杆

### 1. 并行性（SPMD：blocks / cores）

所有核执行同一 kernel，`block_idx`（+ sub-block id）决定工作分配：

- 两维都大时优先 **2D 划分**（如 GEMM 按 m、n 同时切）
- 每 block 的 GM 访问尽量**连续规则**（提升 burst 效率）
- 选每核工作量均衡的划分（避免长尾 block）

### 2. Tiling（选能放下且能复用的尺寸）

- Tile 不超过片上限制，满足 kernel 的 buffer 分区约束
- Tile 形状/布局匹配目标引擎（Cube vs Vector）
- 尽量提高算术强度（每搬运 1 字节做更多计算）

### 3. 数据搬运（减流量、避免冗余变换）

- **复用**：每次 DMA 暂存更多并复用（如 GEMM 的 stepK 缓存）
- **更少变换**：一开始选对输入布局，避免额外 `TTRANS`/`TRESHAPE`/`TEXTRACT`
- **简化输出**：写回 GM 友好且匹配下游消费模式的布局

### 4. 重叠与同步（让流水线满载）

手工 kernel 常用显式双缓冲 + event/flag：

- 当前 `TMATMUL` 跑时启动下一次 `TLOAD`
- 当前计算跑时做下一次 `TEXTRACT`
- 当前 `TSTORE` 跑时准备下一轮计算

经验：只等**真实依赖**，避免稳态循环里全局 drain；把流水线看作 warm-up / steady / drain，优先调顺稳态。

## 五、示例驱动的深度指南（与真实代码绑定）

| 主题 | README | Kernel 代码 |
|------|--------|-------------|
| GEMM（tiling/stepK 缓存/双缓冲） | `kernels/manual/a2a3/gemm_performance/README_zh.md` | `gemm_performance_kernel.cpp` |
| Flash Attention（分阶段 softmax、tiled QK/PV） | `kernels/manual/common/flash_atten/README_zh.md` | `fa_performance_kernel.cpp` |

## 六、常见故障模式

| 症状 | 处理 |
|------|------|
| 某 shape 快、其他 shape 慢 | 针对小/中/大 shape 分别重调核划分与 tile 尺寸 |
| TLOAD 高 + TMATMUL 低 | 提升复用（更大 tile/更好缓存）或修双缓冲；减冗余加载 |
| Transform 占主导 | 提升每次 transform 的计算量；选减少 transform 的布局 |
| 改流水线后正确性出错 | 重核对依赖边，确认每个 consumer 等了正确 producer；先用小 shape 验证 |

## 关联

- 概念：[[pto-overview]]、[[tile-programming-model]]、[[instruction-map]]、[[backend-and-arch]]、[[comm-isa]]
- 代码真源：`kernels/`、`docs/coding/opt_zh.md`
- 工作区 MegaMoE 实战（PTO 全融合 kernel）：`docs/megamoe/README.md`
