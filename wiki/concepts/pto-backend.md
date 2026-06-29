# pto-backend

- **领域**: PTO-ISA 后端与架构映射
- **首次记录**: 2026-06-29
- **来源数**: 1

## 定义

[[pto-isa]] 的核心价值之一：**同一份 PTO 源码可编译到不同后端**，由编译宏选择实现，覆盖 CPU 仿真、NPU 原生（按代际）、CostModel 三类。

## 核心内容

### 三种后端

| 后端 | 使能宏 | 用途 | 同步行为 |
|------|--------|------|----------|
| CPU 仿真 | `__CPU_SIM` | 跨平台功能验证/调试（无需硬件） | `TSYNC` 多为 no-op，靠单线程顺序 |
| NPU 原生 | `__CCE_AICORE__`（A2/A3）、`PTO_NPU_ARCH_A5`（A5） | 真实昇腾硬件执行 | 真实流水线 + Event/flag |
| CostModel | `__COSTMODEL` | 性能仿真：行为验证 + 时延预测 | — |

通信后端分发示例（`pto_comm_instr_impl.hpp`）：A5→`a5/`，A2/A3→`a2a3/`，CPU→`pto/cpu/comm/`。

### CPU 仿真

入门首选，跨平台。需 Python≥3.11、CMake≥3.16、C++20 编译器、`numpy≥1.22`。运行 `python3 tests/run_cpu.py --demo gemm --verbose`。

### NPU 原生（代际）

| 目录 | 架构 | 芯片 |
|------|------|------|
| `include/pto/npu/a2a3/` | A2/A3 | 910B/910C |
| `include/pto/npu/a5/` | A5 | [[ascend-950]] 系列 |
| `include/pto/npu/kirin9030/`、`kirinX90/` | 端侧 Kirin | — |

SoC 由脚本 `-v a3|a5` 选择（`tests/script/run_st.py`、`build.sh --a3 --sim`）。NPU 路径需 Linux + CANN toolkit，运行前 `source set_env_new.sh`。

通信相关架构差异：A2/A3 的 `TPUT_ASYNC`/`TGET_ASYNC` 仅 [[sdma]]；A5 的 `TPUT_ASYNC` = SDMA+MTE 回退+[[urma|URMA]]，`TGET_ASYNC` = SDMA+URMA；URMA 仅 A5（NPU_ARCH 3510，CANN≥9.1.0）。详见 [[pto-comm-isa]]。

### CostModel

| 后端 | 套件 | 重点 |
|------|------|------|
| stub | `st` | 指令级 CostModel 结果验证 |
| fit | `st_fit` | 参数公式估算 cycles/latency |

入口 `include/pto/costmodel/pto_instr.hpp`（stub）、`lightweight_costmodel.hpp`（fit）；fit 公式参数由 `gen_formula_params_header.py` 从 CSV 生成。

### include 目录映射

`common/`（公共 Tile/Event/intrinsic）、`cpu/`（仿真）、`npu/`（原生分代际）、`comm/`（通信，含 a2a3/a5/async_common）、`costmodel/`（stub/fit）。

## 相关

- 实体：[[pto-isa]]、[[ascend-950]]
- 概念：[[pto-tile]]、[[pto-instruction-set]]、[[pto-comm-isa]]、[[pto-kernel-optimization]]
- 资料：[[source-pto-isa]]
