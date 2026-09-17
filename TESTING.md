# 验证与复现 · 0.4.0

默认离线检查重放已保存的独立官方结果，不要求 Python 或网络：

```powershell
./verify.ps1 -MoonPath C:/path/to/moon/bin/moon.exe
```

脚本生成 118 个官方向量，执行 fmt/info、deny-warn、JS/Wasm-GC 各 15 组、重建实际引擎，运行原有七种转换/CLI、1476 项参考重放、11 组新文件/JSONL/HTTP、307 条旧入口异常输入与样例计时。后者不是新增 API 的全面模糊测试。完整源码/证据指纹见 `evidence/context-upgrade.json`。

## 重新运行官方参考

```powershell
python -m pip install --target C:/testdeps/cnnum -r tools/reference-requirements.txt
$env:CN2AN_REFERENCE_DIR='C:/testdeps/cnnum'
./verify.ps1 -MoonPath C:/path/to/moon/bin/moon.exe -WithReference -WithBenchmark
```

`tools/cn2an_oracle.py` 仅导入未修改 cn2an==0.5.24，记录 Python/proces 版本及参考包各 Python 文件 SHA256。案例是本地原创输入；随机种子固定、官方格式输出也用于独立解析对照。未复制参考源码或官方测试集。`number-reference-vectors.json` 保存实际官方结果；`number-reference-validation.json` 明确区分 live 与 saved。

当前 1476 比较：1466 一致、10 有意差异、0 未解释差异；两类数字不得合并为“1476 兼容通过”。有意差异由 `tools/known-differences.json` 固定到具体请求与本库预期结果；任何新差异会令脚本失败。返回数字的官方浮点结果仅在测量外转为十进制字符串、去无意义小数零；大整数及高精度差异不能以容差掩盖。

`reference_vectors_test.mbt` 的 118 个固定案例覆盖格式、四种解析模式、双向句子及逐字模式、接受和拒绝；五组新增公共 API 检查覆盖精确混合计算、单位语法、金额舍入进位、UTF-16 span 与长无效片段。旧接口用原有黄金值和往返检查确认未改变。

## 真实入口

`tools/test-host.mjs` 包含 11 组：精确字符串类型、emoji 位置、实际 CLI 参数/退出码、文件/严格 UTF-8、错误后继续的 JSONL、12000 条有背压消费的批流、最大句子、真实 loopback HTTP、JSON/方法/路径/类型/尺寸错误、chunked 超限和 20 个并发请求。测试结束关闭服务器、清理本次临时目录；不更改系统服务。HTTP 不包含公开部署、TLS、认证或长期负载验收。

本次浏览器通过真实页面操作检查 smart/normal、双向句子、金额默认以及精度错误→half-up/括号路径，共六组；观察到正确输出，无脚本错误、无水平溢出。证据记录 `browser-validation.json`。不是全浏览器、手机或无障碍全面验收。

## 性能

`benchmark-reference.mjs` 与 `benchmark_reference.py` 在同机比较四组：口语/长数解析、数字输出、重复段落中文→数字和数字→中文。每组 3 次预热、7 次批测取中位数；输入和全部结果核对一致。JSON 解析/序列化、进程 I/O 不计时。

MoonBit JS 的解析结果为精确字符串，Python 官方接口返回数值，两者运行时和输出契约不同。报告包含全部输入、循环次数、计时、CPU、平台、引擎 SHA256。它提供样本证据，不能证明所有输入的性能、内存或跨平台成熟度。`tools/benchmark.mjs` 的旧演示计时单独保留，不当作参考性能证据。

历史 `verification.json` 的覆盖率不是当前功能覆盖率；本次未重新测覆盖率。远端 CI 未运行；旧 ZIP/bundle 未更新。
