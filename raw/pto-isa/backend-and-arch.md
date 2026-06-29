# PTO 后端与架构映射（CPU/NPU/CostModel + A2A3/A5）

- **来源**: `code/pto-isa-main` — `include/pto/README_zh.md`、`include/pto/npu/README_zh.md`、`include/pto/comm/README_zh.md`、`docs/costmodel-backends_zh.md`、`docs/getting-started_zh.md`、`README_zh.md`
- **整理日期**: 2026-06-29
- **类型**: 自写综合笔记（基于官方仓库文档）

## 一、三种后端（同一份源码，编译宏分发）

PTO 的核心价值之一：**同一份 PTO 源码可编译到不同后端**，由编译宏选择实现：

| 后端 | 使能宏 | 用途 | 同步行为 |
|------|--------|------|----------|
| **CPU 仿真** | `__CPU_SIM` | 跨平台功能验证、开发调试（macOS/Linux/Windows，无需硬件） | `TSYNC` 多为 no-op，靠单线程程序顺序 |
| **NPU 原生** | `__CCE_AICORE__`（A2/A3）、`PTO_NPU_ARCH_A5`（A5） | 真实昇腾硬件执行 | 真实流水线 + Event/flag |
| **CostModel** | `__COSTMODEL` | 性能仿真：指令行为验证 + 时延预测 | — |

### 通信后端分发示例

`include/pto/comm/pto_comm_instr_impl.hpp` 按宏分发：

```
PTO_NPU_ARCH_A5  → a5/T*.hpp / a5/async/T*Async.hpp
__CCE_AICORE__   → a2a3/T*.hpp / a2a3/async/T*Async.hpp
__CPU_SIM        → pto/cpu/comm/T*.hpp（CPU 仿真 stubs）
```

## 二、CPU 仿真后端

- **定位**：最简单的入门方式，跨平台。功能验证 / 数值对比 / 开发调试的首选。
- **环境**：Python ≥ 3.11、CMake ≥ 3.16、支持 **C++20** 的编译器（Linux GCC 13+/Clang 15+，GCC≥14 启用 bf16）、`numpy ≥ 1.22`。
- **运行**：
  ```bash
  python3 tests/run_cpu.py --clean --verbose       # 全量
  python3 tests/run_cpu.py --demo gemm --verbose   # GEMM demo
  python3 tests/run_cpu.py --demo flash_attn --verbose
  ```
- **特点**：Tile 放主机内存，但保持形状/布局/有效区域规则，便于验证代码合法性与语义一致性。

## 三、NPU 原生后端（架构代际）

NPU 侧实现按 SoC 代际分目录，不同代际有不同优化实现与流水线细节：

| 目录 | 架构 | 对应芯片 |
|------|------|----------|
| `include/pto/npu/a2a3/` | Ascend A2 / A3 | 910B / 910C |
| `include/pto/npu/a5/` | Ascend A5 | 950 系列 |
| `include/pto/npu/kirin9030/`、`kirinX90/` | 端侧 Kirin | — |

每个代际目录里是同名指令的不同实现（`TAdd.hpp`、`TMatmul.hpp`、`TLoad.hpp` …）。

### SoC 选择（构建/测试脚本控制）

```bash
# 通过 -v 选择 SoC：a3 / a5
python3 tests/script/run_st.py -r sim -v a3 -t tadd -g TADDTest.case_float_64x64_64x64
./build.sh --run_all --a3 --sim       # 一键构建并运行推荐测试
```

- `tests/script/run_st.py` / `build_st.py`：`-v a3|a5` 选择
- `tests/npu/<soc>/src/st/CMakeLists.txt`：按 SoC 构建对应 ST 目标
- NPU 路径需 Linux + Ascend CANN toolkit；运行前在工作区根 `source set_env_new.sh`

### 架构差异要点（与通信相关）

| 能力 | A2/A3 | A5（950） |
|------|-------|-----------|
| `TPUT_ASYNC` 后端 | 仅 SDMA | SDMA + MTE 回退 + URMA |
| `TGET_ASYNC` 后端 | 仅 SDMA | SDMA + URMA |
| URMA 引擎 | — | 仅 A5 / NPU_ARCH 3510，要求 CANN ≥ 9.1.0 |

详见 [[comm-isa]]。

## 四、CostModel 后端

CostModel 路径经 `__COSTMODEL` 使能，分两类后端：

| 后端 | 套件名 | 重点 |
|------|--------|------|
| **stub**（打桩） | `st` | 指令级 CostModel 结果验证、支持算子基础行为检查 |
| **fit**（拟合） | `st_fit` | 基于参数公式的 cycles/latency 估算；验证频率/带宽/搬运路径配置的影响 |

### 代码映射

- 通用入口：`include/pto/costmodel/pto_instr.hpp`（stub）、`lightweight_costmodel.hpp`（fit）
- fit 公式实现：`include/pto/costmodel/a2a3/formula_costmodel/formula_backend_compute.hpp`、`formula_backend_transfer.hpp`
- 测试目录：`tests/costmodel/st/`、`tests/costmodel/st_fit/`

### 公式参数生成（仅 fit 需要）

`st_fit` 运行时从 CSV 生成公式参数头：

- 脚本：`include/pto/costmodel/a2a3/formula_costmodel/gen_formula_params_header.py`
- 输入：`formula_params.csv` → 输出：`formula_params_generated.hpp`

### 运行命令

```bash
python3 tests/run_costmodel.py --suite st --testcase tadd --clean --verbose
python3 tests/run_costmodel.py --suite st_fit --testcase time_predict --clean --verbose
bash tests/run_costmodel_tests.sh   # 批量 st + st_fit
```

## 五、include 目录与后端对应

| 目录 | 内容 |
|------|------|
| `include/pto/common/` | 跨后端公共：Tile、Event、intrinsic 声明 |
| `include/pto/cpu/` | CPU 仿真实现 |
| `include/pto/npu/` | NPU 原生实现（按代际分） |
| `include/pto/comm/` | 通信指令（含 a2a3/a5/async_common） |
| `include/pto/costmodel/` | CostModel stub/fit |

## 关联

- 概念：[[pto-overview]]、[[tile-programming-model]]、[[comm-isa]]、[[kernels-practice]]
- 代码真源：`include/pto/`、`tests/`、`docs/getting-started_zh.md`
