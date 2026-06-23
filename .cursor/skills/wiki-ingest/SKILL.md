---
name: wiki-ingest
description: >-
  将资料导入 MyWiki 知识库：从 URL、粘贴文本或 raw/ 本地文件编译为结构化 wiki 页面。
  Use when the user says wiki-ingest, /wiki-ingest, 导入, ingest, or asks to add a source to the wiki.
disable-model-invocation: true
---

# Wiki Ingest

完整导入流水线：source → raw → wiki → 索引 → log。

## 前置

1. 读 `SCHEMA.md` 和 `CLAUDE.md` 中的页面模板
2. 读 `wiki/index.md` 了解现有知识 landscape
3. 读 `raw/index.md` 避免重复导入

## 输入类型

| 输入 | 处理 |
|------|------|
| URL | WebFetch 抓取，保存为 `raw/<标识>.md` |
| 用户粘贴文本 | 保存为 `raw/<标识>.md`，缺 metadata 时询问或推断 |
| `raw/` 已有文件 | 用户指定路径，不修改 raw 内容，只编译 wiki |

PDF/二进制：保存到 `raw/` 或 `raw/assets/`，wiki 中写摘要并引用路径。

## 执行步骤

```
- [ ] 1. 确定资料标识（小写连字符 slug）
- [ ] 2. 若需新增 raw 文件，写入 raw/ 并在 raw/index.md 追加一行
- [ ] 3. 创建 wiki/sources/source-<标识>.md 摘要页
- [ ] 4. 创建或更新 wiki/entities/、wiki/concepts/ 相关页面
- [ ] 5. 建立 [[wikilinks]] 双向交叉引用
- [ ] 6. 标注与已有内容的补充/矛盾关系
- [ ] 7. 更新 wiki/index.md
- [ ] 8. 追加 wiki/log.md
- [ ] 9. 向用户汇报：新建/更新了哪些页面
```

## 原则

- 优先**更新已有页面**，避免重复主题
- 一篇资料通常触及 5–15 个 wiki 文件
- 摘要应**综合**而非照搬，连接已有知识
- 低质量资料导入前先告知用户
- **绝不修改** raw/ 中已有文件内容

## 示例

```
/wiki-ingest raw/ascend-notes.md
/wiki-ingest https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
执行 wiki-ingest：导入 raw/my-article.md
```
