///|
test "decimal exact fractions and signed zero" {
  let cases = [
    ("12.300", "十二点三零零"),
    ("-0.00", "负零点零零"),
    ("-0", "负零"),
    ("10001.0010", "一万零一点零零一零"),
    (
      "0.123456789012345678901234567890", "零点一二三四五六七八九零一二三四五六七八九零一二三四五六七八九零",
    ),
    (
      "9999999999999999.9", "九千九百九十九兆九千九百九十九亿九千九百九十九万九千九百九十九点九",
    ),
  ]
  for (ascii, chinese) in cases {
    assert_eq(@cnnum.format_decimal(ascii), chinese)
    assert_eq(@cnnum.parse_decimal(chinese), ascii)
    assert_eq(
      @cnnum.parse_decimal(@cnnum.format_decimal(ascii, financial=true)),
      ascii,
    )
  }
  assert_eq(@cnnum.format_decimal("00012.030"), "十二点零三零")
}

///|
test "decimal direct reading retains lexical digits" {
  for ascii in ["000123", "-0012.3000", "0", "2026", "-0.00"] {
    assert_eq(@cnnum.parse_digits(@cnnum.format_digits(ascii)), ascii)
    assert_eq(
      @cnnum.parse_digits(@cnnum.format_digits(ascii, financial=true)),
      ascii,
    )
  }
  assert_eq(@cnnum.format_digits("2026"), "二零二六")
  assert_eq(@cnnum.parse_digits("〇〇兩點陸〇", variants=true), "002.60")
}

///|
test "decimal variants are explicit and ambiguity remains rejected" {
  assert_eq(@cnnum.parse_integer("負貳萬零陸", variants=true), -20006L)
  assert_eq(@cnnum.parse_integer("兩百零兩", variants=true), 202L)
  assert_eq(
    @cnnum.parse_decimal("負兩百點參〇", variants=true),
    "-200.30",
  )
  assert_eq(@cnnum.parse_money("負貳萬圓正", variants=true), -2000000L)
  for s in ["兩百", "負貳萬", "〇"] {
    assert_true(
      try {
        ignore(@cnnum.parse_integer(s))
        false
      } catch {
        _ => true
      },
    )
  }
  assert_true(
    try {
      ignore(@cnnum.parse_integer("一萬兩", variants=true))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(@cnnum.parse_money("貳圓正"))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "decimal malformed inputs and exact amount boundaries" {
  for
    s in [
      "",
      "-",
      "+1",
      ".2",
      "1.",
      "1..2",
      "1e2",
      " 1",
      "1-2",
      "10000000000000000",
      "0." + "0".repeat(65),
    ] {
    assert_true(
      try {
        ignore(@cnnum.format_decimal(s))
        false
      } catch {
        _ => true
      },
    )
  }
  for
    s in [
      "",
      "负",
      "点一",
      "一点",
      "一负二",
      "一点负一",
      "一二点三",
      "一万二",
      "一..二",
      "零点" + "一".repeat(65),
    ] {
    assert_true(
      try {
        ignore(@cnnum.parse_decimal(s))
        false
      } catch {
        _ => true
      },
    )
  }
  for s in ["一十", "负负一", "一点", "一点点二", "一负二"] {
    assert_true(
      try {
        ignore(@cnnum.parse_digits(s))
        false
      } catch {
        _ => true
      },
    )
  }
  for
    cents in [
      -9999999999999999L, -101L, -1L, 0L, 1L, 10L, 101L, 9999999999999999L,
    ] {
    assert_eq(
      @cnnum.parse_decimal_cents(@cnnum.format_decimal_cents(cents)),
      cents,
    )
    assert_eq(@cnnum.parse_money(@cnnum.format_money(cents)), cents)
  }
  assert_eq(@cnnum.format_decimal_cents(-1L), "-0.01")
  assert_eq(@cnnum.format_decimal_cents(10L), "0.10")
  assert_true(
    try {
      ignore(@cnnum.format_decimal_cents(10000000000000000L))
      false
    } catch {
      _ => true
    },
  )
}
