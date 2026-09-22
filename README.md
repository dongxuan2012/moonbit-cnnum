> 2026-09-22 当前本地版 0.4.0：申报定位为“精确中文数字、金额与文本区间转换”。已更新[现有项目对照](DUPLICATION.md)、[申报草稿](PROPOSAL.md)及[本轮验证](evidence/innovation-review-20260922/results.json)。下面带日期的旧轮次描述保留历史范围；团队已有公开仓库，本次本地修订尚未由本任务推送。

# 中文数字与金额 · 0.4.0

> 2026-09-21 本地构建修复：命令包 import 已同步到当前 moon.mod 模块名；moon info/check、JS 构建、MoonBit 示例和 Node 引擎示例通过。算法未改，本轮未重跑历史全部行为/性能套件。当前提交指纹见 evidence/module-import-fix.json。

独立 MoonBit 库，新增严格/口语/混合/逐字转换、句子日期/分数/百分比/温度/范围、精确可配置金额，以及 Node 文件、JSONL 和本地 HTTP 入口。原有整数、小数和金额 API 保持原契约。全部本地，未上传；完整追平 20 项目标仍未完成。

## 直接使用

Node.js 24，随仓库附本次编译引擎，无生产 Python 依赖：

```powershell
node tools/number-cli.mjs cn2an --mode smart --input '1万2千3百45'
# 12345
node tools/number-cli.mjs cn2an --mode normal --input '一万二'
# 12000
node tools/number-cli.mjs transform --direction an2cn --input '2026年9月17日，增长12.5%，比例2/3。'
node tools/number-cli.mjs currency --rounding half-up --prefix 人民币 --parentheses --input '-9.995'
# 人民币（壹拾元整）
node tools/number-cli.mjs spans --input '😀第十二章，共1百23元'
node tools/number-cli.mjs jsonl --file requests.jsonl
```

普通命令接受 `--input TEXT`、`--file PATH` 或 UTF-8 stdin；`--json` 返回 `{ok,result}` 或 `{ok:false,error}`。JSONL 每行一个完整请求，逐条输出并处理后续记录；任一记录被拒绝则退出 2，宿主/参数/UTF-8 错误退出 1，全部成功退出 0。输出遵守 stdout 背压。文本文件最多 2 MiB，JSONL 按行有界读取，不把整个文件载入内存。

```json
{"operation":"cn2an","input":"1百23","mode":"smart"}
{"operation":"transform","input":"三分之二，百分之十二点五"}
{"operation":"currency","input":"0.005","rounding":"half-up","zeroYuan":true}
```

`./start-review.ps1` 启动网页。页面提供现有规范转换和新增模式，可调金额前缀、元字、舍入、零元和负数括号。本次已在实际浏览器检查六组路径与页面布局，不代表所有浏览器/设备验收。

## MoonBit API

| 接口 | 契约 |
|---|---|
| `cn2an(text, mode="strict")` | 返回精确十进制字符串；严格拼写、不推断末尾省略 |
| `cn2an(..., mode="normal")` | 另接受逐字数串、两/〇、末位省略；如一百二→120、一万二→12000 |
| `cn2an(..., mode="smart")` | 另展开阿拉伯数字段、全角数和单个单位的小数系数；如1百23、1.2万 |
| `cn2an(..., mode="direct")` | 逐字转数字，保留前后零和负零；不解释单位 |
| `an2cn(text, mode="low" / "up")` | 万/亿分组，小数原样保留；up 为财务大写 |
| `an2cn(..., mode="direct")` | 逐字转写数字、减号和小数点，包括未构成完整数值的字串 |
| `an2cn(..., mode="rmb")` | 紧凑人民币写法，小于一元省略零元；超出两位小数显式采用截断规则 |
| `format_currency` | 默认拒绝多于两位小数；可选 truncate/half-up、元字/整字/前缀、零元和负数括号 |
| `transform` / `transform_spans` | 双向词法转换；后者附原文、替换文本、类别和 UTF-16 起止位置 |

```moonbit
let amount = @cnnum.cn2an("负1.23456789万", mode="smart") // -12345.6789
let text = @cnnum.transform("三分之二，百分之十二点五") // 2/3，12.5%
let currency = @cnnum.format_currency("9.995", rounding="half-up") // 壹拾元整
```

`format_currency` 的命名参数为 `zero_yuan`、`yuan`、`whole_suffix`、`prefix`、`rounding`、`parentheses`。Node JSON 请求使用 `zeroYuan`、`wholeSuffix`。API 清单见 [pkg.generated.mbti](pkg.generated.mbti)。

原有 `format_integer/parse_integer` 使用兆=10^12，仍只接受规范中文；`format_decimal/parse_decimal` 保留最多 64 位精确小数和负零；`format_digits/parse_digits` 保留前导零且要求合法数值结构；`format_money/parse_money` 仍是精确分、规范零元的双向接口。旧 `tools/cli.mjs` 继续可用。新模式不会悄悄改变这些原契约。

## Node 与 HTTP

```javascript
import {convertNumber} from './tools/convert.mjs';
const result = convertNumber({operation:'cn2an', input:'9007199254740993', mode:'smart'});
// "9007199254740993"；数值输入必须为字符串
```

运行 `node tools/http.mjs` 后默认监听 `127.0.0.1:8781`，环境变量 `PORT` 可改端口。`POST /convert` 接受上述 JSON 对象；`GET /health` 检查状态。成功 200、转换拒绝 422、无效 JSON/UTF-8 400、超限 413、类型 415；有请求/头部超时。该入口是本库本地 API，不声称与 cn2an 的公开 HTTP URL/部署接口完全相同，没有安装后台服务。

## 独立证据与差异

固定未修改的 [cn2an 0.5.24](https://pypi.org/project/cn2an/0.5.24/) 和 proces 0.1.7，执行 1476 个独立比较：1466 项一致、10 项有意保留差异、0 项未解释差异。10 项不是通过数：涉及保留混合小数余量/负号、亿后十万的正确求和、拒绝重复符号、温度的中文小数点/负号，以及句中混合数转换。逐项输入、双方输出和原因见 [对照报告](evidence/number-reference-validation.json)。

118 个官方固定向量在 JS/Wasm-GC 各执行；两个后端各 15 组核心检查。11 组真实 CLI/API/HTTP 检查含 12000 条 JSONL、慢输出读取、UTF-8、超长输入、分块请求和并发。四组同机核心计时及结果对照已保存，范围限这些样本，见 [验证与复现](TESTING.md)。

## 范围与剩余工作

数值输入最多 256 个 UTF-16 单元，整数最多 16 位（绝对值≤9999999999999999）、小数最多 64 位。句子最多 262144 个 UTF-16 单元；位置为半开 UTF-16 区间，包含 emoji 时可直接用于 JS slice。原有金额接口范围较小，为绝对值≤99999999999999.99 元。所有精确接口均不经过二进制浮点舍入。

句子转换是确定性词法处理，不识别成语、人名、版本号或真实日期是否合法；如“一心一意”中的一也可能被转换。`direct=true` 只逐字处理，不做分数/日期/温度等特殊规则；无效的最大数字片段保留原文。

尚需更大真实语料、完整上游边界/多版本对照、更多地区/方言规则、HTTP 部署/长期故障和跨平台/内存验证；10 项差异保持可见，不宣称全面兼容。原始代码为本项目原创 MIT，官方 Python 包仅为本地开发参考依赖，未复制其源码或测试集。仓库无 remote；旧 ZIP/Git bundle 未更新，远端 CI 未运行。
