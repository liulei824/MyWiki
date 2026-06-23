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

## [2026-06-23] ingest | 昇腾950 NPU架构白皮书
- 来源: raw/ascend-architecture/昇腾950 NPU架构白皮书.pdf
- 新建: [[source-ascend-950-npu-whitepaper]]
- 新建实体: [[ascend-950]], [[cann]], [[linx816]]
- 新建概念: [[davinci-core-gen3]], [[unified-bus]], [[nddma]], [[stars2]], [[hif8]], [[simd-simt-hybrid]], [[ccu]], [[ascend-super-node]]
- 更新: raw/index.md, wiki/index.md
