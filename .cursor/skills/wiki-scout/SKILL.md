---
name: wiki-scout
description: >-
  为 MyWiki 发现候选资料：分析知识缺口、搜索高质量来源、评估是否值得导入。
  Use when the user says wiki-scout, /wiki-scout, scout, 找资料, or asks to discover sources for a topic.
disable-model-invocation: true
---

# Wiki Scout

发现值得导入的新资料，**只推荐，不自动 ingest**。

## 前置

1. 读 `SCHEMA.md`
2. 读 `wiki/index.md` 和 `raw/index.md` 了解已有覆盖
3. 可选：扫描 wiki 中频繁 [[链接]] 但无独立页面的概念

## 执行步骤

```
- [ ] 1. 明确搜索主题（用户指定，或从知识缺口推断）
- [ ] 2. WebSearch 寻找候选资料（优先：官方文档、论文、高质量技术博客、Karpathy 等 tier-1 来源）
- [ ] 3. 排除已在 raw/index.md 中的资料
- [ ] 4. 评估每条候选：相关性、质量、与已有内容的重叠/补充关系
- [ ] 5. 输出 ranked 列表（3–7 条），每条含：标题、URL、推荐理由、建议 ingest 优先级
- [ ] 6. 询问用户要导入哪几条（不自动 ingest）
- [ ] 7. 追加 wiki/log.md
```

## 评估标准

| 维度 | 说明 |
|------|------|
| 相关性 | 与 wiki 主题（AI/LLM、昇腾 NPU、代码实践）的匹配度 |
| 质量 | 官方 > 论文 > 知名作者博客 > 二手转载 |
| 新颖性 | 补充缺口 vs 重复已有内容 |
| 可操作性 | 是否值得编译进 wiki（非 ephemeral 推文/短讯） |

## 输出格式

```markdown
## Scout 结果：<主题>

1. **[标题](URL)** — 推荐理由。优先级：高/中/低
2. ...
```

## 原则

- **绝不自动 ingest** — 等用户确认后再用 `wiki-ingest`
- 优先填补 index 中薄弱或缺失的概念
- 追加 log，不修改 wiki 内容（除非用户要求）

## 示例

```
/wiki-scout 昇腾 CANN 算子开发
/wiki-scout LLM Wiki 相关实践文章
执行 wiki-scout：帮我找 MoE 推理优化的优质资料
```
