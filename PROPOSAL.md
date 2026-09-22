# 精确中文数字、金额与文本区间转换

本地申报候选材料，2026-09-22；模块 `dongxuan2012/cnnum`，版本 `0.4.0`。团队的公开仓库可能还是先前提交，本次没有推送；最终表单必须指向团队实际上传版本。

## 要解决的任务

在账单/表单文本转换中保住超过 IEEE-754 精确整数范围的十进制数字，并明确金额舍入、口语省略、百分比和原文位置。

以下是目标任务和可复现工程证据，不虚构客户、存量部署或采用人数。

## 现有工作与新增贡献

[lqyq666/bodymate/zhnum](https://github.com/lqyq666/bodymate)。承认 bodymate/zhnum 已有中文数字反向解析与归一化。差异集中于精确十进制、多模式及金额舍入、原文区间回写，而非“中文数字反向解析空白”。

MoonBit 负责精确字符串运算、模式解析、金额舍入与区间转换；Node 提供文件、JSONL 和本地 HTTP。

- [lqyq666/bodymate 固定提交](https://github.com/lqyq666/bodymate/tree/319c6750f22b9d8f3e9df410ea93aa12a4356818)：依据该版本的公开说明对照，不冒充本轮运行了对方全部实现。

## 可复现路径

仓库附编译引擎；修改源码后先构建。参考工具的额外依赖与环境变量见 TESTING.md；测试创建的网络服务仅在本机。

```sh
node tools/number-cli.mjs currency --rounding half-up --prefix 人民币 --parentheses --input -9.995
node tools/test-convert.mjs
node tools/test-host.mjs
```

7 组转换模式及精度 CLI、本地宿主路径通过；金额示例输出人民币（壹拾元整）。 本轮 JS/WasmGC 核心测试及 JS 构建通过，原始日志见 [本轮验证](evidence/innovation-review-20260922/results.json)。测试数量证明所列范围，不能代替创新性论证或推断正式审核通过。

## 边界与来源

不是所有中文自然语言理解；不是金融计算认证。地区/口语歧义有显式模式，不能自动猜出所有作者意图。

许可证与来源沿用仓库现有 LICENSE/第三方说明，不将标准、算法、词库或参考软件写成本项目发明。查重不是对全生态不存在的证明，日期、相邻项与未覆盖范围见 [DUPLICATION.md](DUPLICATION.md)。
