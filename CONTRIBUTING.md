# Contributing locally

This is an independent repository. Do not import or reference sibling repositories. Run `./verify.ps1 -MoonPath /absolute/path/to/moon` before committing. Add public-API regressions for behavioral changes; document unsupported syntax and observable errors. `moon fmt` and `moon info` must be idempotent. Generated JS must be rebuilt with the library.

Use `node tools/cli.mjs --help` for the original interface, `node tools/number-cli.mjs --help` for structured file/JSONL usage, and `node tools/test-host.mjs` for actual CLI/HTTP checks. The original `tools/benchmark.mjs` measures only the JS example; TESTING.md documents the separate pinned cn2an comparison and its timing limits. Keep documented intentional differences visible instead of counting them as reference compatibility passes.
