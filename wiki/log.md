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

## [2026-06-29] cleanup | 移除 CANN 生态外部代码镜像
- 删除: raw/cann-ecosystem-manifest.md
- 删除 wiki 页: [[source-pto-isa-overview]], [[source-pto-isa-comm-isa]], [[pto-isa]], [[pto-comm-isa]]
- 更新: raw/index.md, wiki/index.md, [[cann]], [[urma]], [[sdma]], [[ccu]]
- 原因: 外部镜像 ingest 方式不再采用，后续另行设计代码理解方案

## [2026-06-29] setup | code/reference 目录重组
- liulei `code/` 下除 pto-isa-main 外全部迁入 `code/reference/`
- 更新: AGENTS.md、cann-open-source-repos.md

## [2026-06-29] setup | 基于 pto-isa-main 生成 PTO raw 文档
- 新建 raw/pto-isa/: pto-overview, tile-programming-model, instruction-map, backend-and-arch, comm-isa, kernels-practice（共 6 篇）
- 来源: code/pto-isa-main 官方文档（README/PTOISA/coding/isa/comm/auto_mode/costmodel + include 头）
- 说明: 方案 B 独立综合，允许与 docs/pto-isa-knowledge 重叠（用户后续自行删除该专题库）
- 更新: raw/index.md（登记 6 篇）
- 待办: 如需编译进 wiki，执行 wiki-ingest

## [2026-06-29] setup | PTO 资料目录与 CANN 仓索引
- 新建: raw/pto-isa/（自写 PTO 笔记落盘位置）
- 新建: raw/cann-open-source-repos.md（CANN 开源仓 clone 地址 + 代码回查流程）
- 更新: SCHEMA.md、.cursor/rules/llm-wiki.mdc、wiki-query Skill、raw/README.md

## [2026-06-29] setup | 异步通信文档搬入 raw + 内容校正
- 搬入 raw/pto-isa/: comm-async-sdma, comm-async-urma, comm-async-ccu（原 docs/pto-isa-knowledge/communication/async/）
- 校正: SDMA 源文件索引路径（npu/comm→comm/async/sdma；async_types/event_impl→async_common；TPut/TGetAsync→a2a3/a5+async_common），URMA/CCU 路径已准确
- 清理: 三篇指向（将删除的）pto-isa-knowledge 旧结构的相对链接 → 改 wikilink/代码引用
- 更新: raw/index.md（登记 3 篇）

## [2026-06-29] ingest | PTO-ISA 全套笔记编译进 wiki
- 新建 source: [[source-pto-isa]]（覆盖 6 篇核心笔记）、[[source-pto-comm]]（覆盖 comm-isa + 3 异步后端）
- 新建实体: [[pto-isa]]
- 新建概念: [[pto-tile]], [[pto-instruction-set]], [[pto-backend]], [[pto-comm-isa]], [[pto-kernel-optimization]]
- 更新: [[sdma]], [[urma]], [[ccu]]（补 PTO 软件视角，来源数→2）、[[cann]]（链接 pto-isa，来源数→2）、wiki/index.md
- 来源: raw/pto-isa/ 9 篇（事实源 code/pto-isa-main）

## [2026-06-29] ingest | A2/A3 vs A5 SDMA SQE 结构对比
- 新建 source: [[source-sdma-sqe-comparison]]
- 更新: [[sdma]]（新增 A2/A3↔A5 SQE 差异节，来源数→3）、raw/index.md、wiki/index.md
- 来源: raw/sdma/a23_vs_a5_sdma_sqe_comparison.md（shmem vs hcomm 源码对比）
