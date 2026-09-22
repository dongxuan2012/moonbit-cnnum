# 精确中文数字、金额与文本区间转换

**本项目仓库：[https://github.com/dongxuan2012/moonbit-cnnum](https://github.com/dongxuan2012/moonbit-cnnum)**

模块 `dongxuan2012/cnnum`，本地版本 **0.4.0**，MIT。当前评审状态：**条件复审**。本文件是当前入口，旧轮次说明与详细用法保存在 [历史/完整使用说明](README-BEFORE-VALUE-REWORK.md)。

## 解决什么任务

在账单/表单文本转换中保住超过 IEEE-754 精确整数范围的十进制数字，并明确金额舍入、口语省略、百分比和原文位置。

需要超过 2^53 的精确十进制、明确舍入及原文区间时评估；普通整数读写与既有 zhnum 重叠。

## 直接复现

安装 MoonBit 和 Node.js 24，在本仓库根目录运行：

```sh
moon build --target js
node -e "require('node:fs').copyFileSync('_build/js/debug/build/cmd/web/web.js','web/engine.mjs')"
node examples/run-use-case.mjs
```

流程：**精确金额及原文区间转换**。运行器创建新的系统临时目录，保留每一步的 stdout/stderr、产物及 `report.json`，打印实际目录；重复运行不会覆盖之前产物。它只执行仓库内的本地样例，不连接公网或发送消息。`report.json` 的 `expected` 是应观察的结果，实际结果在各步输出中；成功退出不替代内容核对。

输入性质：原创合成文本；演示精度/显式舍入/区间，不是财务认证。

应观察：大整数 9007199254740993 原样保留；-9.995 按 half-up 处理，区间使用 API 声明的 UTF-16 坐标。

具体命令和输入路径见 [使用任务](USE-CASE.md) 与 [机器可读流程](examples/use-case.json)。只把这个脚本当复现入口，不把通用运行器计作核心技术贡献。

## 实现与已有项目的关系

MoonBit 负责精确字符串运算、模式解析、金额舍入与区间转换；Node 提供文件、JSONL 和本地 HTTP。

承认 bodymate/zhnum 已有中文数字反向解析与归一化。差异集中于精确十进制、多模式及金额舍入、原文区间回写，而非“中文数字反向解析空白”。

同类项目和检索边界见 [DUPLICATION](DUPLICATION.md)。查重用于避免错误的首创表述；关键词零结果不能证明生态空白，Node 宿主能力也不计为 MoonBit 原生 I/O。

库使用从 [公共 API](pkg.generated.mbti) 和根包源码开始；可在本 checkout 的消费包中导入 `"dongxuan2012/cnnum"`。源码中的网络/文件宿主入口及完整参数仍见 [完整使用说明](README-BEFORE-VALUE-REWORK.md)。是否已发布到 Mooncakes 需另核实，本文不把 `moon add` 的下载成功作为已完成事项。

## 验证与边界

7 组转换模式及精度 CLI、本地宿主路径通过；金额示例输出人民币（壹拾元整）。

[上一轮工程验证](evidence/innovation-review-20260922/results.json) 与 [本轮最小任务回执](evidence/value-rework-20260922/use-case.json) 分开。历史参考版本、golden 重放、本机 peer、真实第三方服务端和本次样例是不同证据，不能合并成“全部生产验证”。

常规核心检查可运行 `moon check --target js`、`moon test --target js`、`moon test --target wasm-gc`。专项命令：

```sh
node tools/number-cli.mjs currency --rounding half-up --prefix 人民币 --parentheses --input -9.995
node tools/test-convert.mjs
node tools/test-host.mjs
```

专项所需的参考环境和历史版本见原使用说明及 TESTING 文档；本轮回执只记录实际执行项，不声称上面所有参考服务在任意环境即装即跑。

不是所有中文自然语言理解；不是金融计算认证。地区/口语歧义有显式模式，不能自动猜出所有作者意图。

## 复审材料状态

必须用精度、金额和区间差异说明价值，不能只写中文数字转换。

2026-09-22 匿名新克隆成功；默认分支 `main`，核验公开提交 `f303f821d706885e6f9a3c0c0e79e1073bcf87ab`。本轮源码修订仅在本地，尚未推送；此记录不证明当时报名表中的地址正确，也不证明新修订已上线。

[申报草稿](PROPOSAL.md) 已压缩为 30 行以内，并单独标明本项目仓库；[复核说明](REVIEW-RESPONSE.md) 区分材料错误、功能变化及尚未解决的问题。没有编造用户、设备接入、生产部署或评审认可。
