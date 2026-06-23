# nddma

- **类型**: 概念
- **领域**: 昇腾算子/数据搬运
- **首次记录**: 2026-06-23
- **来源数**: 1

## 定义

**NDDMA**（N-dimensional Direct Memory Access Engine）是 [[davinci-core-gen3]] AI Core 内置的多维 DMA 引擎（见 [[ascend-glossary]]），在 Kernel 层完成 Global Memory 到 Vector **Unified Buffer** 的数据搬运与 Layout 变换。

## 核心能力

- 最多 **5 维**数据重排 + 搬运 + 转置，一步完成
- 典型 Layout：**NCHW ↔ NHWC** 等排布与对齐转换
- 目标：Global Memory → [[vector-core]] UB（512KB/Core）

## 微架构优势

- **地址生成逻辑硬化**，减少 CPU 式地址计算开销
- **内置缓存**发掘局部性
- 将细粒度读合并为 **128 字节**读操作，提升内存效率

## 使用示例（概念）

从 Global Memory 中间隔规律的数据块（如 1,2,3,5,6,7…）按序读入 UB：配置 NDDMA 参数即可，无需手写复杂寻址循环。

## 与 SDMA 对比

| | **NDDMA** | **[[sdma]]** |
|---|-----------|--------------|
| 层级 | AI Core 内，Kernel 指令 | 系统级，[[stars2]] 调度 |
| 范围 | GM → UB，多维重排 | 芯片内/间、Memory↔[[l2-cache]] |
| 典型场景 | 算子内 Layout 变换 | 全局拷贝、CMO |

## 协同

- [[cv-fusion]] / FlashAttention pipeline：见 [[flashattention-optimization]]
- 流水线同步：[[bufferid-sync]]

## 相关

- 概念：[[davinci-core-gen3]]、[[vector-core]]、[[cv-fusion]]、[[sdma]]、[[bufferid-sync]]
- 实体：[[ascend-950]]
- 综合：[[flashattention-optimization]]、[[ascend-glossary]]
- 资料：[[source-ascend-950-npu-whitepaper]]
