# CANN 生态外部代码镜像

> 源码**不在** my-wiki 仓库内，仅在此登记路径与版本。Ingest / Query 时 Agent 读取外部路径。

## 镜像根目录

| 平台 | 路径 |
|------|------|
| Mac | `/Users/liulei/cann-code` |
| Linux | `~/cann-code`（建议与 Mac 保持一致） |

## 已登记仓库

| 标识 | Mac/Linux 路径 | 远程 | 版本 | 最近同步 |
|------|----------------|------|------|----------|
| pto-isa | `/Users/liulei/cann-code/pto-isa` | https://gitcode.com/cann/pto-isa.git | 9.1.0 @ `6321d9a2` | 2026-06-24 |

## 使用约定

- 外部镜像**只读**：仅 `git pull`，ingest 时不修改源码
- Ingest 后更新本表 commit 列
- 权威文档路径（pto-isa）：
  - 通信 ISA：`docs/isa/comm/README_zh.md`
  - 通信 API：`include/pto/comm/pto_comm_inst.hpp`
  - 通信实现：`include/pto/comm/`
