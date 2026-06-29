# CANN 开源仓库索引与代码回查约定

> **用途**：登记 CANN 生态各开源仓库的下载地址与本地路径映射；当 wiki / raw 中找不到代码细节时，Agent 按本文「代码回查流程」检索或拉取源码。
>
> **维护**：发现新仓库或本地 clone 路径变化时更新本文件；完整官方清单以 manifest 为准。

## 官方组织与全量清单

| 项 | 值 |
|----|-----|
| GitCode 组织 | https://gitcode.com/cann |
| Clone URL 前缀 | `https://gitcode.com/cann/<仓库名>.git` |
| 全量 manifest（约 55 仓） | https://gitcode.com/cann/manifest.git |
| 一键拉全栈 | `repo init -u https://gitcode.com/cann/manifest -b master && repo sync -j8` |

manifest 是版本对齐的**权威索引**；本文件只维护常用仓与**本地已有 clone** 的快捷映射。

## 本地代码根目录

MyWiki 位于 liulei 工作区时，优先在下列路径查找本地 clone：

| 环境 | 主开发（pto-isa） | 参考仓根目录 |
|------|-------------------|--------------|
| Linux（NPU 机） | `/mnt/data/ntlab/liulei/code/pto-isa-main` | `/mnt/data/ntlab/liulei/code/reference/` |
| Mac | `~/code/pto-isa-main` | `~/code/reference/` |

**Clone 落盘约定**：

- **pto-isa**（主开发）：`<本地 code 根>/pto-isa-main/`（或你惯用的主副本目录名）
- **其余 CANN 仓**（只读参考）：`<本地 code 根>/reference/<仓库名>/`

## 已登记仓库

### 编程与 Tile ISA

| 仓库名 | 说明 | Clone |
|--------|------|-------|
| pto-isa | PTO Tile 虚拟 ISA 实现库 | `git clone https://gitcode.com/cann/pto-isa.git` |
| pypto | PyPTO 编程框架 | `git clone https://gitcode.com/cann/pypto.git` |
| asc-devkit | Ascend C 算子开发语言与工具链 | `git clone https://gitcode.com/cann/asc-devkit.git` |
| catlass | 矩阵乘等算子模板库 | `git clone https://gitcode.com/cann/catlass.git` |
| pyasc | Python Ascend C 绑定 | `git clone https://gitcode.com/cann/pyasc.git` |

### 算子库

| 仓库名 | 说明 | Clone |
|--------|------|-------|
| ops-nn | 神经网络类算子 | `git clone https://gitcode.com/cann/ops-nn.git` |
| ops-math | 数学类基础算子 | `git clone https://gitcode.com/cann/ops-math.git` |
| ops-transformer | Transformer 大模型算子 | `git clone https://gitcode.com/cann/ops-transformer.git` |
| ops-cv | 计算机视觉算子 | `git clone https://gitcode.com/cann/ops-cv.git` |

### 通信

| 仓库名 | 说明 | Clone |
|--------|------|-------|
| hccl | 集合通信库 | `git clone https://gitcode.com/cann/hccl.git` |
| hcomm | 通信运行时组件 | `git clone https://gitcode.com/cann/hcomm.git` |
| shmem | 共享内存通信 | `git clone https://gitcode.com/cann/shmem.git` |
| hixl | 通信相关组件 | `git clone https://gitcode.com/cann/hixl.git` |

### 图引擎与运行时

| 仓库名 | 说明 | Clone |
|--------|------|-------|
| ge | Graph Engine 图编译与执行 | `git clone https://gitcode.com/cann/ge.git` |
| metadef | 算子与图元数据定义 | `git clone https://gitcode.com/cann/metadef.git` |
| runtime | CANN 运行时 | `git clone https://gitcode.com/cann/runtime.git` |
| graph-autofusion | 图自动融合（含 SuperKernel） | `git clone https://gitcode.com/cann/graph-autofusion.git` |

### 示例与学习

| 仓库名 | 说明 | Clone |
|--------|------|-------|
| cann-samples | 官方示例 | `git clone https://gitcode.com/cann/cann-samples.git` |
| cann-learning-hub | 学习中心 | `git clone https://gitcode.com/cann/cann-learning-hub.git` |
| community | 社区治理与贡献指引 | `git clone https://gitcode.com/cann/community.git` |

### 工程公共

| 仓库名 | 说明 | Clone |
|--------|------|-------|
| cmake | CANN 工程公共 cmake | `git clone https://gitcode.com/cann/cmake.git` |

## 本地已有 clone（快捷映射）

以下路径在 liulei Linux 工作区**已存在**，代码回查时**优先**使用，勿重复 clone：

| 仓库名 | 本地路径 | 备注 |
|--------|----------|------|
| pto-isa | `/mnt/data/ntlab/liulei/code/pto-isa-main` | 主开发副本 |
| pto-isa（参考） | `/mnt/data/ntlab/liulei/code/reference/pto-isa` | 只读对照 clone |
| pypto | `/mnt/data/ntlab/liulei/code/reference/pypto` | |
| ops-transformer | `/mnt/data/ntlab/liulei/code/reference/ops-transformer` | |
| hccl | `/mnt/data/ntlab/liulei/code/reference/hccl` | |
| hcomm | `/mnt/data/ntlab/liulei/code/reference/hcomm` | |
| shmem | `/mnt/data/ntlab/liulei/code/reference/shmem` | |
| runtime | `/mnt/data/ntlab/liulei/code/reference/cann-runtime` | 目录名与远程仓名不同 |
| vllm-ascend | `/mnt/data/ntlab/liulei/code/reference/vllm-ascend` | |
| tilelang-ascend | `/mnt/data/ntlab/liulei/code/reference/tilelang-ascend` | |

未在上表出现的参考仓，按 `code/reference/<仓库名>/` 推断路径；不存在则 clone 到该路径。

## 代码回查流程（Agent 必遵）

当问题涉及**实现细节、API 签名、宏定义、调用链**等，且 `wiki/` 与 `raw/`（含 `raw/pto-isa/`）中**找不到**足够信息时：

```
1. 读本文，根据主题确定目标「仓库名」
2. 查「本地已有 clone」表 → 若存在，直接在该路径内 grep / 读源码
3. 若 `code/reference/<仓库名>/` 存在但未登记 → 同样优先使用
4. 本地仍无 → git clone 到 `code/reference/<仓库名>/`（pto-isa 主开发副本除外，见上表；需网络；clone 前可告知用户）
5. 在源码中定位答案，回答时引用具体文件路径与行号
6. 若结论有长期价值 → 建议用户整理摘要到 raw/（如 raw/pto-isa/）再 wiki-ingest
```

### 边界

- **只读源码**：回查过程不修改 CANN 开源仓代码
- **先 wiki 后代码**：仅当 wiki/raw 不足时才下钻源码；勿跳过知识库直接读代码
- **版本**：未指定版本时以本地 clone 当前 HEAD 为准；若与文档版本冲突，在回答中标注
- **不镜像进 MyWiki**：禁止将整个代码仓复制或 submodule 进 `raw/`；只 ingest 自写摘要

### PTO-ISA 专题

PTO 相关笔记放 `raw/pto-isa/`；代码真源优先 `code/pto-isa-main`。工作区另有专题知识库 `docs/pto-isa-knowledge/`（liulei 根目录），与 MyWiki 互补。

## 关联

- MyWiki 约定：仓库根 `SCHEMA.md`「代码回查」章节
- 工作区子项目索引：liulei 根目录 `AGENTS.md`
