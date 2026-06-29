---
name: wiki-query
description: >-
  基于 MyWiki 已编译知识回答问题，附 wiki 页面引用，可选归档为 qa/ 或 syntheses/ 页面。
  Use when the user says wiki-query, /wiki-query, 查询, query, or asks questions about wiki content.
disable-model-invocation: true
---

# Wiki Query

从 wiki 编译层回答，而非凭空生成。

## 执行步骤

```
- [ ] 1. 读 wiki/index.md 定位相关页面
- [ ] 2. 读所有相关 wiki 页面（sources/ entities/ concepts/ syntheses/ qa/）
- [ ] 3. 若 wiki 信息不足，再查 raw/ 原始资料（含 raw/pto-isa/）
- [ ] 4. 若仍缺代码实现细节，读 raw/cann-open-source-repos.md，按「代码回查流程」搜本地 code/ 或 clone 源码
- [ ] 5. 综合回答，明确标注信息来源（[[页面名]]、raw 文件或源码路径）
- [ ] 6. 区分「wiki 中的内容」与「训练数据中的常识」与「源码回查结论」
- [ ] 7. 若回答有长期价值，询问是否归档到 wiki/qa/、wiki/syntheses/ 或摘要进 raw/pto-isa/
```

## 回答格式

- 先给结论，再展开
- 引用格式：`（见 [[概念名]]）` 或 `（见 source-xxx）`
- wiki 无足够信息时，明确说明缺口；涉及 CANN 代码细节时走 `raw/cann-open-source-repos.md` 回查流程

## 原则

- **必须先读 index**，再读具体页面
- 不要仅凭标题猜测内容
- 多页面相关时，全部读完再综合
- 不要把训练数据包装成 wiki 内容

## 示例

```
/wiki-query CANN 算子开发有哪些关键步骤？
/wiki-query 知识库里关于 LLM Wiki 范式的总结
执行 wiki-query：昇腾 NPU 和 CUDA 编程模型有何异同？
```
