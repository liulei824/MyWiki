---
name: wiki-lint
description: >-
  对 MyWiki 做健康检查：死链、孤立页、index 不一致、矛盾陈述、覆盖缺口。
  Use when the user says wiki-lint, /wiki-lint, lint, 维护, or asks to health-check the wiki.
disable-model-invocation: true
---

# Wiki Lint

全面检查 wiki 结构与内容健康度。

## 前置

1. 读 `SCHEMA.md`
2. 读 `wiki/index.md` 枚举应存在的页面
3. 扫描 `wiki/` 下所有 `.md`（除 index.md、log.md）
4. 读 `raw/index.md` 对照 `raw/` 实际文件

## 结构检查

```
- [ ] 死链：[[页面]] 指向不存在的文件
- [ ] 缺失反向链接：A→B 存在但 B 未链回 A
- [ ] 孤立页：wiki 中有文件但 index.md 未收录
- [ ] 幽灵条目：index.md 列出但文件不存在
- [ ] raw 不一致：raw/ 有文件但 raw/index.md 未登记，或反之
```

## 内容检查

```
- [ ] 矛盾：不同页面陈述冲突且未标注
- [ ] 覆盖缺口：被 [[链接]] 3 次以上但无独立页面的概念
- [ ] 薄页面：实质内容少于约 5 句，可扩展
- [ ] 过时：已被新资料取代但未标注
```

## 输出报告

分两级：

**Errors（必须修复）**：死链、幽灵条目、index 严重不一致

**Warnings（建议修复）**：缺反向链接、薄页面、覆盖缺口、未标注矛盾

## 修复

- 结构问题：可直接修复（补链接、更新 index、补 raw/index 行）
- 内容问题：标注后询问用户是否扩展或 ingest 新资料
- 修复后追加 `wiki/log.md`

## 示例

```
/wiki-lint
执行 wiki-lint 检查知识库
运行 lint，修复所有结构性错误
```
