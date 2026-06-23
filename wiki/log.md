# 操作日志

> 按时间追加，不删除历史记录。

## [2026-06-23] init | 知识库框架初始化
- 创建目录结构：raw/, wiki/{sources,entities,concepts,syntheses,qa}/
- 创建 CLAUDE.md 行为契约
- 创建 index.md 与 log.md

## [2026-06-23] setup | 安装 Wiki Skills
- 新增 SCHEMA.md、raw/index.md
- 安装 Skills：wiki-ingest, wiki-query, wiki-lint, wiki-scout
- 更新 .cursor/rules/llm-wiki.mdc
