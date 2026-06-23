# LLM Wiki — 个人知识库

## 目的

维护 liulei 的个人知识库。主题涵盖 AI/LLM 工程、昇腾 NPU 开发、代码实践、阅读笔记与研究工作。
知识库通过持续导入（Ingest）、查询（Query）、维护（Lint）不断复利积累。

## 目录结构

```
my-wiki/
├── raw/                  # 原始资料（只读，LLM 不得修改）
│   └── assets/           # 图片、附件
├── wiki/                 # LLM 维护的结构化知识页面
│   ├── index.md          # 内容目录（查询入口）
│   ├── log.md            # 操作日志（按时间追加）
│   ├── sources/          # 资料摘要页（source-*.md）
│   ├── entities/         # 实体页（人物、工具、公司、框架）
│   ├── concepts/         # 概念页（方法论、模式、技术原理）
│   ├── syntheses/        # 跨资料综合页
│   └── qa/               # 有价值的问答归档
├── SCHEMA.md             # 约定与索引规则（Skill 执行前必读）
├── CLAUDE.md             # 本文件：行为契约
└── .cursor/skills/       # wiki-ingest / query / lint / scout
```

## Skills

本仓库安装了 4 个项目级 Skill（位于 `.cursor/skills/`）：

| Skill | 触发示例 | 作用 |
|-------|----------|------|
| `wiki-ingest` | `/wiki-ingest raw/xxx.md` | 导入资料到 wiki |
| `wiki-query` | `/wiki-query 关于 XXX 的问题` | 基于 wiki 回答 |
| `wiki-lint` | `/wiki-lint` | 健康检查 |
| `wiki-scout` | `/wiki-scout 主题` | 发现候选资料 |

执行 Skill 前先读 `SCHEMA.md`。详细步骤见各 Skill 文件。

## 命名规范

- 文件名使用小写英文或中文，用连字符分隔：`cann-operator-dev.md`
- 资料摘要：`wiki/sources/source-<简短标识>.md`
- 实体页：`wiki/entities/<实体名>.md`
- 概念页：`wiki/concepts/<概念名>.md`
- 综合页：`wiki/syntheses/<主题>.md`
- 问答归档：`wiki/qa/<日期>-<主题>.md`
- 链接使用 Obsidian 风格双向链接：`[[页面名]]`

## 页面模板

### 资料摘要页（sources/source-*.md）

```markdown
# <资料标题>

- **来源**: <URL 或文件路径>
- **导入日期**: YYYY-MM-DD
- **类型**: 文章 | 论文 | 笔记 | 文档 | 实验记录

## 核心要点
（3-7 条 bullet）

## 详细摘要
（结构化段落）

## 关联
- 实体：[[实体A]]、[[实体B]]
- 概念：[[概念A]]、[[概念B]]
- 相关摘要：[[source-xxx]]

## 与已有知识的关联
- **补充**：...
- **矛盾**：...（如有，必须标注，不得静默覆盖）
```

### 实体页（entities/*.md）

```markdown
# <实体名>

- **类型**: 人物 | 工具 | 公司 | 框架 | 硬件
- **首次记录**: YYYY-MM-DD
- **来源数**: N

## 概述
（一句话定义 + 展开说明）

## 关键事实
（随新资料更新，保留来源引用）

## 相关
- 概念：[[...]]
- 资料：[[source-...]]
```

### 概念页（concepts/*.md）

```markdown
# <概念名>

- **领域**: ...
- **首次记录**: YYYY-MM-DD
- **来源数**: N

## 定义

## 核心内容
（随导入不断更新）

## 不同观点 / 矛盾
（如有冲突，并列呈现并标注来源）

## 相关
- 实体：[[...]]
- 概念：[[...]]
- 资料：[[source-...]]
```

## 工作流

Ingest / Query / Lint / Scout 的详细步骤见 `.cursor/skills/` 下对应 Skill 文件及 `SCHEMA.md`。

简要说明：
- **Ingest**：raw → wiki 编译，更新 index、log、raw/index
- **Query**：先 wiki 后 raw，附引用，可选归档 qa/syntheses
- **Lint**：结构 + 内容健康检查，修复后写 log
- **Scout**：发现候选资料，只推荐不自动导入

## index.md 维护规则

`wiki/index.md` 按类别组织，每条目格式：

```
- [[页面名]] — 一句话摘要（来源数: N，更新: YYYY-MM-DD）
```

类别：资料摘要 | 实体 | 概念 | 综合 | 问答

每次 Ingest 或新建页面后必须更新 index。

## log.md 维护规则

追加格式（便于 grep）：

```
## [YYYY-MM-DD] ingest | <资料标题>
- 新建: [[source-xxx]], [[概念A]]
- 更新: [[实体B]]

## [YYYY-MM-DD] query | <问题摘要>
- 回答归档: [[qa/xxx]]（如有）

## [YYYY-MM-DD] lint
- 修复死链 N 处，新建概念页 M 个
```

## 边界

- **绝不修改** `raw/` 下的任何文件
- **不删除** wiki 页面，过时内容标注「已被取代」并链接新页面
- 不确定时向用户确认，而非猜测
