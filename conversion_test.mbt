///|
test "number modes unit grammar and mixed exact arithmetic" {
  for
    (source, result) in [
      ("一百二", "120"),
      ("一万二千三", "12300"),
      ("一亿零一万", "100010000"),
      ("两点两", "2.2"),
      ("〇〇三", "3"),
    ] {
    assert_eq(@cnnum.cn2an(source, mode="normal"), result)
  }
  for
    (source, result) in [
      ("1百23", "123"),
      ("1万23", "10023"),
      ("一百01", "101"),
      ("负1.2万", "-12000"),
      ("1.23456789万", "12345.6789"),
      ("0.00000000000000001", "0.00000000000000001"),
      ("9007199254740993", "9007199254740993"),
      ("1点23", "1.23"),
    ] {
    assert_eq(@cnnum.cn2an(source, mode="smart"), result)
  }
  assert_eq(@cnnum.cn2an("一亿十万"), "100100000")
  assert_eq(@cnnum.cn2an("一萬零十"), "10010")
  for
    source in [
      "一百二", "一千一十", "两百", "〇", "一点零", "一千零一百",
      "一亿一", "一百零十", "一万万", "一亿亿",
    ] {
    assert_true(
      try {
        ignore(@cnnum.cn2an(source))
        false
      } catch {
        _ => true
      },
    )
  }
  for
    source in [
      "负-1.2万",
      "一万002",
      "1.2万3千",
      "1e3",
      "10000000000000000",
      "",
      "一亿".repeat(100),
    ] {
    assert_true(
      try {
        ignore(@cnnum.cn2an(source, mode="smart"))
        false
      } catch {
        _ => true
      },
    )
  }
}

///|
test "number formatting wan yi direct and preservation" {
  assert_eq(@cnnum.an2cn("1000100000001"), "一万零一亿零一")
  assert_eq(@cnnum.an2cn("-0.00"), "负零点零零")
  assert_eq(
    @cnnum.an2cn("００１２．３０", mode="up"),
    "壹拾贰点叁零",
  )
  assert_eq(@cnnum.an2cn("1..2", mode="direct"), "一点点二")
  assert_eq(@cnnum.cn2an("〇〇三点零", mode="direct"), "003.0")
  assert_eq(@cnnum.an2cn("0.10", mode="rmb"), "壹角")
  assert_eq(@cnnum.an2cn("1.239", mode="rmb"), "壹元贰角叁分")
  // Existing precision and canonical money contracts remain separate.
  assert_eq(@cnnum.format_money(10L), "零元壹角")
  assert_eq(@cnnum.format_integer(1000000000000L), "一兆")
}

///|
test "currency styles exact rounding and carry" {
  assert_eq(
    @cnnum.format_currency(
      "-0.005",
      rounding="half-up",
      zero_yuan=true,
      prefix="人民币",
      yuan="圆",
      whole_suffix="正",
      parentheses=true,
    ),
    "人民币（零圆壹分）",
  )
  assert_eq(@cnnum.format_currency("9.995", rounding="half-up"), "壹拾元整")
  assert_eq(
    @cnnum.format_currency("-9.995", rounding="half-up"),
    "负壹拾元整",
  )
  assert_eq(@cnnum.format_currency("1.009", rounding="truncate"), "壹元整")
  assert_eq(
    @cnnum.format_currency("9999999999999999.99"),
    "玖仟玖佰玖拾玖万玖仟玖佰玖拾玖亿玖仟玖佰玖拾玖万玖仟玖佰玖拾玖元玖角玖分",
  )
  for source in ["1.001", "1e3", "NaN", "10000000000000000"] {
    assert_true(
      try {
        ignore(@cnnum.format_currency(source))
        false
      } catch {
        _ => true
      },
    )
  }
  assert_true(
    try {
      ignore(@cnnum.format_currency("9999999999999999.995", rounding="half-up"))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "sentence dates fractions percentages temperatures and ranges" {
  assert_eq(
    @cnnum.transform(
      "二〇二四年十二月三十一日，温度零下三点五摄氏度，增长百分之十二点五，比例三分之二",
    ),
    "2024年12月31日，温度-3.5℃，增长12.5%，比例2/3",
  )
  assert_eq(
    @cnnum.transform(
      "2024年12月31日，-3.5℃，12.5%，2/3",
      direction="an2cn",
    ),
    "二零二四年十二月三十一日，负三点五摄氏度，百分之十二点五，三分之二",
  )
  assert_eq(
    @cnnum.transform("电话003，1-2个月", direction="an2cn", direct=true),
    "电话零零三，一-二个月",
  )
  assert_eq(
    @cnnum.transform("电话003，1-2个月", direction="an2cn"),
    "电话三，一到二个月",
  )
  assert_eq(
    @cnnum.transform("一点二万和一万二"),
    "一点二万和12000",
  )
  assert_eq(
    @cnnum.transform("编号一二三，电话号码零零三", direct=true),
    "编号123，电话号码003",
  )
}

///|
test "sentence spans unicode offsets and bounded malformed runs" {
  let source = "😀第十二章，共1百23元"
  let spans = @cnnum.transform_spans(source)
  assert_eq(spans.length(), 2)
  assert_eq(spans[0].start, 3)
  assert_eq(spans[0].end, 5)
  for span in spans {
    assert_eq(source[span.start:span.end].to_owned(), span.source)
  }
  assert_eq(@cnnum.transform(source), "😀第12章，共123元")
  let long = "一".repeat(10000)
  assert_eq(@cnnum.transform(long), long)
  assert_true(
    try {
      ignore(@cnnum.transform("x".repeat(262145)))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(@cnnum.transform("", direction="bad"))
      false
    } catch {
      _ => true
    },
  )
}
