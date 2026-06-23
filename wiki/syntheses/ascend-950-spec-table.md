# ascend-950-spec-table

- **类型**: 综合
- **来源**: [[source-ascend-950-npu-whitepaper]] 表3-1、表4-2
- **更新**: 2026-06-23

## 说明

昇腾950 通过冗余设计衍生多规格版本（如 32/28 Cube 等）。下表为白皮书主要规格；满配/次配数值以 **/** 分隔。

## 表3-1 主要算力与系统规格

### AI 子系统规模

| 规格项 | 950PR | 950DT |
|--------|-------|-------|
| Cube Core 数量 | 32 / 28 | 36 / 32 / 28 |
| Vector Core 数量 | 64 / 56 | 72 / 64 / 56 |

### Cube + Vector 合计算力

| 精度 | 950PR (TFLOPS/TOPS) | 950DT (TFLOPS/TOPS) |
|------|---------------------|---------------------|
| MXFP4 | 1784 / 1561 | 2007 / 1784 / 1561 |
| HiF8 / MXFP8 / FP8 | 919 / 804 | 1034 / 919 / 804 |
| INT8 | 919 / 804 | 1034 / 919 / 804 |
| BF16 / FP16 | 486 / 425 | 547 / 486 / 425 |
| TF32 | 243 / 212 | 273 / 243 / 212 |

### Cube 算力

| 精度 | 950PR | 950DT |
|------|-------|-------|
| MXFP4 | 1730 / 1513 | 1946 / 1730 / 1513 |
| HiF8 / MXFP8 / FP8 | 865 / 756 | 973 / 865 / 756 |
| INT8 | 865 / 756 | 973 / 865 / 756 |
| BF16 / FP16 | 432 / 378 | 486 / 432 / 378 |
| TF32 | 216 / 189 | 243 / 216 / 189 |

### Vector 算力

| 精度 | 950PR | 950DT |
|------|-------|-------|
| FP16 / BF16 | 54 / 47 | 60 / 54 / 47 |
| FP32 | 27 / 23 | 30 / 27 / 23 |
| INT8 | 54 / 47 | 60 / 54 / 47 |
| INT16 | 27 / 23 | 30 / 27 / 23 |
| INT32 | 13 / 11 | 15 / 13 / 11 |
| INT64 | 6 / 5 | 7 / 6 / 5 |

### Memory 与 SOC

| 规格项 | 950PR | 950DT |
|--------|-------|-------|
| 片上内存容量 | 128 / 112 GB | 144 / 96 GB |
| 片上内存带宽 | 1.6 / 1.4 TB/s | 4 TB/s |
| L2 Cache 容量 | 128 / 112 MB | 128 MB |
| AI CPU | Linx816 8C16T / 6C12T / 4C8T | Linx816 8C16T / 6C12T |
| L2 Cache 配置 | 512B Line，4×128B Sector，L2 Hint，CMO | 同左 |

### DVPP（满配）

| 模块 | 950PR | 950DT |
|------|-------|-------|
| VPC | 4 / 2 Core，5760/2880 FPS@1080P | 4 / 2 Core，5760/2880 FPS@1080P |
| JPEGD | 8 Core，4096 FPS@1080P，最大 32K×32K | 同左 |
| JPEGE | 4 / 2 Core，1024/512 FPS@1080P，最大 32K×32K | 同左 |

### IO（Unified Bus）

| 规格项 | 950PR | 950DT |
|--------|-------|-------|
| 互联协议 | URMA-CTP、URMA-TP、UB Memory、PCIe 5.0、UBoE | 同左 |
| UB 带宽 | 18 Port × 112Gbps，2016GB/s 双向 | 同左 |
| UBoE | 2 Port × 400Gbps（与 UB 共用端口） | 同左 |
| PCIe | 5.0 x16，128GB/s 双向（与 UB 共用 4 Port） | 同左 |

## 表4-2 Memory 层级（每 Core / 芯片级）

详见 [[memory-hierarchy]]。

| Memory | 大小 |
|--------|------|
| L1 Buffer | 512KB / AI Core |
| L0A / L0B Buffer | 64KB / AI Core |
| L0C Buffer | 256KB / AI Core |
| Unified Buffer | 512KB / AI Core |
| CPU L1 / L2 | 64KB / 1MB per CPU Core |
| L3 Cache | 4MB / CPU Cluster |
| L2 Cache | 最高 128MB（芯片级） |
| 950PR 片上内存 | 最高 128GB |
| 950DT 片上内存 | 最高 96 / 144GB |

## 相关

- 实体：[[ascend-950]]
- 综合：[[ascend-950pr-vs-950dt]]
- 概念：[[memory-hierarchy]]、[[l2-cache]]、[[dvpp]]
- 资料：[[source-ascend-950-npu-whitepaper]]
