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

## [2026-06-23] lint | 首次健康检查
- Errors: 0（无死链、无幽灵条目、index 一致）
- Warnings: 缺反向链接 1 处；薄页面 2 个；白皮书覆盖缺口 15+ 主题
- 输出: 建议补充清单（见对话）

## [2026-06-23] ingest | Lint 第一批补充（7 项）
- 来源: [[source-ascend-950-npu-whitepaper]]（深化编译，未改 raw）
- 新建综合: [[ascend-950-spec-table]], [[ascend-950pr-vs-950dt]]
- 新建概念: [[memory-hierarchy]], [[l2-cache]], [[dvpp]], [[urma]], [[ub-memory]]
- 更新: [[ascend-950]], [[unified-bus]], [[stars2]], [[ccu]], wiki/index.md
- 修复: [[unified-bus]] ↔ [[stars2]] 双向链接

## [2026-06-23] ingest | Lint 第二批补充（5 项）
- 来源: [[source-ascend-950-npu-whitepaper]]（深化编译）
- 新建概念: [[cube-core]], [[vector-core]], [[cv-fusion]], [[sdma]]
- 新建问答: [[2026-06-23-950pr-vs-950dt]]
- 更新: [[davinci-core-gen3]], [[l2-cache]], [[stars2]], [[nddma]], [[simd-simt-hybrid]], [[ascend-950]], wiki/index.md

## [2026-06-23] ingest | Lint 第三批补充
- 来源: [[source-ascend-950-npu-whitepaper]]（深化编译）
- 新建综合: [[ascend-glossary]], [[flashattention-optimization]]
- 新建概念: [[uboe]], [[pcie-gen5]], [[bufferid-sync]], [[chiplet-uma]]
- 加厚: [[cann]], [[nddma]]
- 更新: [[unified-bus]], [[ascend-950]], [[davinci-core-gen3]], [[cv-fusion]], wiki/index.md

## [2026-06-24] ingest | pto-isa 代码仓（通信指令）
- 来源: 外部镜像 `/Users/liulei/cann-code/pto-isa` @ 6321d9a2
- 新建: [[cann-ecosystem-manifest]]
- 新建实体: [[pto-isa]]
- 新建概念: [[pto-comm-isa]]
- 新建资料: [[source-pto-isa-overview]], [[source-pto-isa-comm-isa]]
- 更新: [[cann]], [[urma]], [[sdma]], [[ccu]], raw/index.md, wiki/index.md
