# 中文数字与金额

MoonBit 0.3.0 本地审查版本。支持中文整数、精确小数、逐字数字和人民币大写互转。
原始字符串和整数分保留精度，不经浮点数转换；源码、工具和网页均在本独立仓库。

## 直接试用

`./start-review.ps1` 后打开 http://127.0.0.1:8780/web/ 。页面提供七种转换方式，接受自定义输入，
可选择财务大写或繁体/异体字输入；所有转换均调用已编译的 MoonBit 引擎。

Node.js 命令行（无需安装包）：

```powershell
node tools/cli.mjs --mode decimal --input '-0.0012300'
# 负零点零零一二三零零
node tools/cli.mjs --mode parse-decimal --input '十二点三零零' --json
# {"ok":true,"output":"12.300"}
node tools/cli.mjs --mode parse-money --variants --input '負貳圓正'
# -2.00
node tools/cli.mjs --mode digits --input '002026'
# 零零二零二六
```

模式：money、parse-money、decimal、parse-decimal、digits、parse-digits、parse-integer。
`--financial` 选择财务大写，`--variants` 接受文末所列异体字。`--file` 读取 UTF-8 文件，
未指定输入源时读取标准输入；`--json` 输出结构化结果。
保留旧版未传 `--mode` 的金额演示入口及退出码：成功 0、无效转换输入 2、宿主/参数错误 1。
新模式严格使用输入文本，文件或标准输入的末尾换行也会检查。

## 公共 API

| 接口 | 输入与结果 |
| --- | --- |
| format_integer / parse_integer | Int64 与规范中文整数互转 |
| format_decimal / parse_decimal | ASCII 小数字符串与中文小数互转，保留小数末尾零和负零 |
| format_digits / parse_digits | 逐字互转，不解释十百千万，保留前导零 |
| format_money / parse_money | 精确整数分与规范大写金额互转 |
| parse_decimal_cents / format_decimal_cents | ASCII 金额与整数分互转，后者总输出两位小数 |

`financial=true` 用于 format_integer、format_decimal、format_digits。
`variants=true` 用于 parse_integer、parse_decimal、parse_digits、parse_money；默认关闭。
公共 API 清单由工具链生成，见 [pkg.generated.mbti](pkg.generated.mbti)。

```moonbit
let text = @cnnum.format_decimal("12.300") // 十二点三零零
let exact = @cnnum.parse_decimal(text) // 12.300
let cents = @cnnum.parse_money("負貳圓正", variants=true) // -200
let amount = @cnnum.format_decimal_cents(cents) // -2.00
```

## 输入契约与范围

- 中文整数的绝对值最多 9,999,999,999,999,999；兆固定为 10^12。
- 小数整数部分沿用上述范围，小数部分最多 64 位，不接受指数、千分符、加号或空白。
  小数格式化会规范化整数前导零；逐字模式保留前导零。逐字模式总长度最多 256 字符。
- 金额绝对值最多 99,999,999,999,999.99 元，只接受精确角分，超过两位小数会报错，不自动舍入。
- 异体字选项映射 負/萬/億/貳/參/陸/兩/两/〇/點；金额另支持 圓/圆→元、正→整。
  映射后仍检查规范结构，“一万二”等省略表达不会推断成某个金额。
- Money 采用本库规范形式：如零元壹角、壹元零伍分。异体字选项不是任意自然语言金额解析器。

## 验证与开发

安装 MoonBit 后运行 `./verify.ps1`，或传 `-MoonPath` 指定编译器路径。
该脚本为完整本项目工作流；仅改动小数模块时可运行：

```powershell
moon test --target js --filter 'decimal*' --deny-warn
moon info
moon build --target js --deny-warn
# 更新 web/engine.mjs 为本次编译产物后
node tools/test-convert.mjs
```

本轮执行了 4 组新增 MoonBit 测试、7 种实际编译入口的固定值验证、精确长小数 CLI 验证和错误输入验证，
记录在 [evidence/decimal-focused-validation.json](evidence/decimal-focused-validation.json)。
覆盖最大金额、负零、30 位小数、前后导零、显式异体字及格式拒绝。
旧整数和金额的大规模往返记录属于历史验证，本轮没有重复运行全量测试。
网页已接入接口，本轮未进行浏览器视觉验收。未执行独立 cn2an 程序对照。

## 对标与剩余差距

参照 [cn2an 官方功能说明](https://github.com/Ailln/cn2an)比较了小数、逐字模式和金额能力。
尚缺混合阿拉伯/中文单位解析、句子中的日期/分数/百分比转换、更多口语规范与可配置金额输出风格。
这些差距仍保留在后续计划中，本版不声称已全面追平参照项目。
本项目按明确规则自行实现，没有复制参照项目源码或测试集，原创代码采用 MIT。
查重检索范围见 [DUPLICATION.md](DUPLICATION.md)，不能据此保证没有同类项目。

仅保存在本地，没有设置远程仓库、上传或发布。`localreview` 为本地命名空间。
当前源码是后续开发主版本，旧批次及 ZIP/bundle 为历史审查快照，本轮未重新打包。
