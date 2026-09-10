# 可执行 API 示例

增加规范人民币大写金额逆向解析，4000 个金额往返用例。这些例子调用公开 API，并随 `moon test` 执行。

```mbt check
///|
test "financial money parser roundtrip and canonical rejection" {
  for i in -2000..<2000 {
    assert_eq(
      @cnnum.parse_money(@cnnum.format_money(i.to_int64())),
      i.to_int64(),
    )
  }
  for s in ["一元整", "负零元整", "壹元伍分伍分", "壹元"] {
    assert_true(
      try {
        ignore(@cnnum.parse_money(s))
        false
      } catch {
        _ => true
      },
    )
  }
}
```

限制：仅接受本库规范金额格式；非规范、方言或自然语言金额不自动猜测。
