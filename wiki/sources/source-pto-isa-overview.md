# PTO-ISA 代码仓概览

- **来源**: 外部镜像 `/Users/liulei/cann-code/pto-isa` @ `6321d9a2`
- **导入日期**: 2026-06-24
- **类型**: 代码仓

## 核心要点

- **PTO Tile Library**：CANN 官方 Tile 编程 ISA 实现与文档
- 支持 **A2/A3/A5 + CPU Simulator**；A5 对应 [[ascend-950]]
- **Auto / Manual** 双模式；CostModel 性能仿真（A5）
- **通信扩展**：点对点、信号同步、集合通信（详见 [[pto-comm-isa]]）
- 新闻里程碑：2026-02-28 核间通信指令；2026-03-30 A5 异步通信 + CostModel

## 通信指令入口（用户关注）

| 文档 | 路径（镜像内） |
|------|----------------|
| 通信 ISA 总览 | `docs/isa/comm/README_zh.md` |
| 公共 API | `include/pto/comm/pto_comm_inst.hpp` |
| 实现结构 | `include/pto/comm/README_zh.md` |
| 通信 ST 测试 | `tests/npu/a5/comm/st/`、`tests/npu/a2a3/comm/st/` |

## 与昇腾950 wiki 知识的关联

- 异步 `TPUT_ASYNC`/`TGET_ASYNC` 可选 **URMA** 引擎 → [[urma]]、[[unified-bus]]
- SDMA 路径 → [[sdma]]、[[stars2]]
- A5 集合通信 CCU 测试用例 → [[ccu]]
- Manual kernel 示例：`kernels/manual/a5/gemm_ar`、`allgather_gemm`、`moe_dispatch/combine`

## 开发路径

1. CPU 仿真验证：`python3 tests/run_cpu.py`
2. 通信 ST：`tests/run_comm_test.sh`（同步/异步分类）
3. NPU 性能案例：`kernels/manual/a5/`

## 关联

- 实体：[[pto-isa]]、[[cann]]、[[ascend-950]]
- 概念：[[pto-comm-isa]]
- 登记：[[cann-ecosystem-manifest]]

## 与已有知识的关联

- **补充**：CANN 生态首个代码仓编译进 wiki；通信指令与 [[urma]]/[[sdma]]/[[ccu]] 形成交叉引用
