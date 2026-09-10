///|
test "Chinese grouping golden examples" {
  let cases = [
    (0L, "零"),
    (10L, "十"),
    (11L, "十一"),
    (20L, "二十"),
    (101L, "一百零一"),
    (10001L, "一万零一"),
    (100010001L, "一亿零一万零一"),
    (-10010L, "负一万零一十"),
    (1000000000001L, "一兆零一"),
  ]
  for pair in cases {
    assert_eq(@cnnum.format_integer(pair.0), pair.1)
    assert_eq(@cnnum.parse_integer(pair.1), pair.0)
  }
}

///|
test "roundtrip 20000 integers and boundary groups" {
  for n in -10000..<10000 {
    let v = n.to_int64()
    assert_eq(@cnnum.parse_integer(@cnnum.format_integer(v)), v)
    assert_eq(@cnnum.parse_integer(@cnnum.format_integer(v, financial=true)), v)
  }
  for
    v in [
      9999999999999999L, -9999999999999999L, 100001000L, 100100000L, 101000000L,
    ] {
    assert_eq(@cnnum.parse_integer(@cnnum.format_integer(v)), v)
  }
}

///|
test "money exact fractions" {
  for
    pair in [
      (0L, "零元整"),
      (105L, "壹元零伍分"),
      (10L, "零元壹角"),
      (1L, "零元壹分"),
      (-10001L, "负壹佰元零壹分"),
      (123456L, "壹仟贰佰叁拾肆元伍角陆分"),
    ] {
    assert_eq(@cnnum.format_money(pair.0), pair.1)
  }
  assert_eq(@cnnum.parse_decimal_cents("-100.01"), -10001L)
  assert_eq(@cnnum.parse_decimal_cents("0.1"), 10L)
}

///|
test "reject ambiguity and malformed money" {
  for
    s in [
      "", "负", "一万二", "一二三", "百百", "一亿亿", "零零", "负零",
      "十猫",
    ] {
    assert_true(
      try {
        ignore(@cnnum.parse_integer(s))
        false
      } catch {
        _ => true
      },
    )
  }
  for
    s in [
      "", "-", ".1", "1.", "1.234", "1e2", "1.2.3", "100000000000000", "NaN",
    ] {
    assert_true(
      try {
        ignore(@cnnum.parse_decimal_cents(s))
        false
      } catch {
        _ => true
      },
    )
  }
}
