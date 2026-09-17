///|
test "official cn2an cross-backend golden acceptance and values" {
  let cases = [
    ("an2cn", "0", "low", "cn2an", false, true, "零"),
    ("an2cn", "0", "up", "cn2an", false, true, "零"),
    ("an2cn", "0", "rmb", "cn2an", false, true, "零元整"),
    ("an2cn", "0", "direct", "cn2an", false, true, "零"),
    ("an2cn", "-0", "low", "cn2an", false, true, "负零"),
    ("an2cn", "-0", "up", "cn2an", false, true, "负零"),
    ("an2cn", "-0", "rmb", "cn2an", false, true, "负零元整"),
    ("an2cn", "-0", "direct", "cn2an", false, true, "负零"),
    ("an2cn", "-0.00", "low", "cn2an", false, true, "负零点零零"),
    ("an2cn", "-0.00", "up", "cn2an", false, true, "负零点零零"),
    ("an2cn", "-0.00", "rmb", "cn2an", false, true, "负零元整"),
    ("an2cn", "-0.00", "direct", "cn2an", false, true, "负零点零零"),
    ("an2cn", "00012", "low", "cn2an", false, true, "十二"),
    ("an2cn", "00012", "up", "cn2an", false, true, "壹拾贰"),
    ("an2cn", "00012", "rmb", "cn2an", false, true, "壹拾贰元整"),
    ("an2cn", "00012", "direct", "cn2an", false, true, "零零零一二"),
    ("an2cn", "0.10", "low", "cn2an", false, true, "零点一零"),
    ("an2cn", "0.10", "up", "cn2an", false, true, "零点壹零"),
    ("an2cn", "0.10", "rmb", "cn2an", false, true, "壹角"),
    ("an2cn", "0.10", "direct", "cn2an", false, true, "零点一零"),
    ("an2cn", "0.01", "low", "cn2an", false, true, "零点零一"),
    ("an2cn", "0.01", "up", "cn2an", false, true, "零点零壹"),
    ("an2cn", "0.01", "rmb", "cn2an", false, true, "壹分"),
    ("an2cn", "0.01", "direct", "cn2an", false, true, "零点零一"),
    ("an2cn", "1e3", "low", "cn2an", false, false, ""),
    ("an2cn", "1e3", "up", "cn2an", false, false, ""),
    ("an2cn", "1e3", "rmb", "cn2an", false, false, ""),
    ("an2cn", "1e3", "direct", "cn2an", false, false, ""),
    ("an2cn", "+1", "low", "cn2an", false, false, ""),
    ("an2cn", "+1", "up", "cn2an", false, false, ""),
    ("an2cn", "+1", "rmb", "cn2an", false, false, ""),
    ("an2cn", "+1", "direct", "cn2an", false, false, ""),
    ("an2cn", "-.1", "low", "cn2an", false, false, ""),
    ("an2cn", "-.1", "up", "cn2an", false, false, ""),
    ("an2cn", "-.1", "rmb", "cn2an", false, false, ""),
    ("an2cn", "10000000000000000", "low", "cn2an", false, false, ""),
    ("an2cn", "10000000000000000", "up", "cn2an", false, false, ""),
    ("an2cn", "10000000000000000", "rmb", "cn2an", false, false, ""),
    ("an2cn", "1..2", "low", "cn2an", false, false, ""),
    ("an2cn", "1..2", "up", "cn2an", false, false, ""),
    ("an2cn", "1..2", "rmb", "cn2an", false, false, ""),
    ("an2cn", " 1", "low", "cn2an", false, false, ""),
    ("an2cn", " 1", "up", "cn2an", false, false, ""),
    ("an2cn", " 1", "rmb", "cn2an", false, false, ""),
    ("an2cn", " 1", "direct", "cn2an", false, false, ""),
    ("an2cn", "", "direct", "cn2an", false, false, ""),
    ("cn2an", "一百二", "strict", "cn2an", false, false, ""),
    ("cn2an", "一百二", "normal", "cn2an", false, true, "120"),
    ("cn2an", "一百二", "smart", "cn2an", false, true, "120"),
    ("cn2an", "一百二", "direct", "cn2an", false, false, ""),
    ("cn2an", "一千二", "strict", "cn2an", false, false, ""),
    ("cn2an", "一千二", "normal", "cn2an", false, true, "1200"),
    ("cn2an", "一千二", "smart", "cn2an", false, true, "1200"),
    ("cn2an", "一千二", "direct", "cn2an", false, false, ""),
    ("cn2an", "一万二", "strict", "cn2an", false, false, ""),
    ("cn2an", "一万二", "normal", "cn2an", false, true, "12000"),
    ("cn2an", "一万二", "smart", "cn2an", false, true, "12000"),
    ("cn2an", "一万二", "direct", "cn2an", false, false, ""),
    ("cn2an", "一亿二", "strict", "cn2an", false, false, ""),
    ("cn2an", "一亿二", "normal", "cn2an", false, false, ""),
    ("cn2an", "一亿二", "smart", "cn2an", false, false, ""),
    ("cn2an", "一亿二", "direct", "cn2an", false, false, ""),
    ("cn2an", "一百零二", "strict", "cn2an", false, true, "102"),
    ("cn2an", "一百零二", "normal", "cn2an", false, true, "102"),
    ("cn2an", "一百零二", "smart", "cn2an", false, true, "102"),
    ("cn2an", "一百零二", "direct", "cn2an", false, false, ""),
    ("cn2an", "一千二三", "strict", "cn2an", false, false, ""),
    ("cn2an", "一千二三", "normal", "cn2an", false, false, ""),
    ("cn2an", "一千二三", "smart", "cn2an", false, false, ""),
    ("cn2an", "一千二三", "direct", "cn2an", false, false, ""),
    ("cn2an", "一百二三", "strict", "cn2an", false, false, ""),
    ("cn2an", "一百二三", "normal", "cn2an", false, false, ""),
    ("cn2an", "一百二三", "smart", "cn2an", false, false, ""),
    ("cn2an", "一万二三", "normal", "cn2an", false, false, ""),
    ("cn2an", "一万二三", "smart", "cn2an", false, false, ""),
    ("cn2an", "一百二十三四", "normal", "cn2an", false, false, ""),
    ("cn2an", "一百二十三四", "smart", "cn2an", false, false, ""),
    ("cn2an", "十二三", "normal", "cn2an", false, false, ""),
    ("cn2an", "十二三", "smart", "cn2an", false, false, ""),
    ("cn2an", "一二三", "normal", "cn2an", false, true, "123"),
    ("cn2an", "一二三", "smart", "cn2an", false, true, "123"),
    ("cn2an", "一二三", "direct", "cn2an", false, true, "123"),
    ("cn2an", "零零三", "normal", "cn2an", false, true, "3"),
    ("cn2an", "零零三", "smart", "cn2an", false, true, "3"),
    ("cn2an", "零零三", "direct", "cn2an", false, true, "003"),
    ("cn2an", "〇", "direct", "cn2an", false, true, "0"),
    ("cn2an", "负零", "strict", "cn2an", false, true, "0"),
    ("cn2an", "负零", "direct", "cn2an", false, true, "-0"),
    ("cn2an", "一十", "strict", "cn2an", false, true, "10"),
    ("cn2an", "一百一十", "strict", "cn2an", false, true, "110"),
    ("cn2an", "一亿一万", "strict", "cn2an", false, true, "100010000"),
    ("cn2an", "一亿零一万", "strict", "cn2an", false, true, "100010000"),
    ("cn2an", "１２３", "direct", "cn2an", false, true, "123"),
    ("cn2an", "-123", "direct", "cn2an", false, true, "-123"),
    (
      "transform", "编号一二三，电话号码零零三", "", "cn2an", false,
      true, "编号123，电话号码3",
    ),
    (
      "transform", "编号一二三，电话号码零零三", "", "cn2an", true,
      true, "编号123，电话号码003",
    ),
    (
      "transform", "编号一二三，电话号码零零三", "", "an2cn", false,
      true, "编号一二三，电话号码零零三",
    ),
    (
      "transform", "编号一二三，电话号码零零三", "", "an2cn", true,
      true, "编号一二三，电话号码零零三",
    ),
    (
      "transform", "二〇二四年十二月三十一日，温度零下三点五摄氏度，增长百分之十二点五，比例三分之二",
      "", "cn2an", false, true, "2024年12月31日，温度-3.5℃，增长12.5%，比例2/3",
    ),
    (
      "transform", "二〇二四年十二月三十一日，温度零下三点五摄氏度，增长百分之十二点五，比例三分之二",
      "", "cn2an", true, true, "2024年十二月三十一日，温度0下3.5摄氏度，增长百分之十二点五，比例3分之2",
    ),
    (
      "transform", "二〇二四年十二月三十一日，温度零下三点五摄氏度，增长百分之十二点五，比例三分之二",
      "", "an2cn", false, true, "二〇二四年十二月三十一日，温度零下三点五摄氏度，增长百分之十二点五，比例三分之二",
    ),
    (
      "transform", "二〇二四年十二月三十一日，温度零下三点五摄氏度，增长百分之十二点五，比例三分之二",
      "", "an2cn", true, true, "二〇二四年十二月三十一日，温度零下三点五摄氏度，增长百分之十二点五，比例三分之二",
    ),
    (
      "transform", "2024年12月31日，-3.5℃，12.5%，2/3", "", "cn2an", false,
      true, "2024年12月31日，-3.5℃，12.5%，2/3",
    ),
    (
      "transform", "2024年12月31日，-3.5℃，12.5%，2/3", "", "cn2an", true,
      true, "2024年12月31日，-3.5℃，12.5%，2/3",
    ),
    (
      "transform", "2024年12月31日，-3.5℃，12.5%，2/3", "", "an2cn", true,
      true, "二零二四年一二月三一日，负三点五℃，一二点五%，二/三",
    ),
    (
      "transform", "1-2个月，-1到-2，版本1.2.3，abc123def", "", "cn2an",
      false, true, "1-2个月，-1到-2，版本1.2.3，abc123def",
    ),
    (
      "transform", "1-2个月，-1到-2，版本1.2.3，abc123def", "", "cn2an",
      true, true, "1-2个月，-1到-2，版本1.2.3，abc123def",
    ),
    (
      "transform", "1-2个月，-1到-2，版本1.2.3，abc123def", "", "an2cn",
      false, true, "一到二个月，负一到负二，版本一点二.三，abc一百二十三def",
    ),
    (
      "transform", "1-2个月，-1到-2，版本1.2.3，abc123def", "", "an2cn",
      true, true, "一-二个月，负一到负二，版本一点二.三，abc一二三def",
    ),
    (
      "transform", "一点二万和一万二", "", "cn2an", false, true, "一点二万和12000",
    ),
    (
      "transform", "一点二万和一万二", "", "cn2an", true, true, "一点二万和一万二",
    ),
    (
      "transform", "一点二万和一万二", "", "an2cn", false, true, "一点二万和一万二",
    ),
    (
      "transform", "一点二万和一万二", "", "an2cn", true, true, "一点二万和一万二",
    ),
    (
      "transform", "二氧化碳与一心一意，星期一，第十二章", "",
      "cn2an", false, true, "2氧化碳与1心1意，星期1，第12章",
    ),
    (
      "transform", "二氧化碳与一心一意，星期一，第十二章", "",
      "cn2an", true, true, "2氧化碳与1心1意，星期1，第十二章",
    ),
    (
      "transform", "二氧化碳与一心一意，星期一，第十二章", "",
      "an2cn", false, true, "二氧化碳与一心一意，星期一，第十二章",
    ),
    (
      "transform", "二氧化碳与一心一意，星期一，第十二章", "",
      "an2cn", true, true, "二氧化碳与一心一意，星期一，第十二章",
    ),
    (
      "transform", "负百分之三", "", "an2cn", false, true, "负百分之三",
    ),
  ]
  for (operation, source, mode, direction, direct, accepted, expected) in cases {
    let result = try {
      let actual = match operation {
        "cn2an" => @cnnum.cn2an(source, mode~)
        "an2cn" => @cnnum.an2cn(source, mode~)
        _ => @cnnum.transform(source, direction~, direct~)
      }
      accepted && actual == expected
    } catch {
      _ => !accepted
    }
    assert_true(result, msg=operation + "/" + mode + ": " + source)
  }
}
