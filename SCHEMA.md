# MyWiki Schema

本文件定义 MyWiki 的全部约定。**执行任何 wiki 操作前必须先读此文件。**

## 架构

两层结构（Karpathy LLM Wiki 范式）：

1. **Raw Sources（`raw/`）** — 不可变的原始资料。Agent 只读不改。事实来源。
2. **Wiki（`wiki/`）** — Agent 维护的结构化知识，由 raw 编译而来。

原始资料的元数据集中在 `raw/index.md`，raw 文件本身保持「纯 raw」。

## 目录

```
raw/                    # 原始资料 + assets/
wiki/
  index.md              # 查询入口
  log.md                # 操作日志
  sources/              # source-*.md 资料摘要
  entities/             # 实体页
  concepts/             # 概念页
  syntheses/            # 跨资料综合
  qa/                   # 问答归档
```

## 命名

- 文件名：小写英文或中文，连字符分隔，如 `cann-operator-dev.md`
- 资料摘要：`wiki/sources/source-<标识>.md`
- 实体：`wiki/entities/<名>.md`
- 概念：`wiki/concepts/<名>.md`
- 综合：`wiki/syntheses/<主题>.md`
- 问答：`wiki/qa/<YYYY-MM-DD>-<主题>.md`
- 链接：`[[页面名]]`（Obsidian wikilink，不含路径）

## 索引文件

### wiki/index.md

按类别列出所有页面，每条：

```
- [[页面名]] — 一句话摘要（来源数: N，更新: YYYY-MM-DD）
```

类别：资料摘要 | 实体 | 概念 | 综合 | 问答

### raw/index.md

原始资料登记表（markdown 表格）：

```
| 标识 | 标题 | 作者 | 日期 | 类型 | 来源 |
```

### wiki/log.md

追加式日志，格式：

```
## [YYYY-MM-DD] ingest | <标题>
## [YYYY-MM-DD] query | <问题>
## [YYYY-MM-DD] lint
## [YYYY-MM-DD] scout | <主题>
```

## 链接规则

- 使用 `[[wikilinks]]` 交叉引用
- 优先维护**双向链接**：A 链到 B 时，B 的相关章节应链回 A
- 链接名与目标文件名（不含 `.md`）一致

## 页面模板

详见 `CLAUDE.md` 中的模板章节。所有 wiki 页面应包含：标题、元信息、结构化正文、关联章节。

## 操作概要

| 操作 | Skill | 说明 |
|------|-------|------|
| Ingest | `wiki-ingest` | raw → wiki 编译 |
| Query | `wiki-query` | 基于 wiki 回答 |
| Lint | `wiki-lint` | 结构与健康检查 |
| Scout | `wiki-scout` | 发现候选资料 |

## 边界

- **绝不修改** `raw/` 内已有文件（Ingest 可新增 raw 文件，但不得改已有内容）
- **不删除** wiki 页面；过时内容标注「已被取代」并链接新页
- Scout **只推荐、不自动导入**
- 新资料与旧知识冲突时**标注矛盾**，不静默覆盖
