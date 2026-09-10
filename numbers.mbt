///|
pub suberror NumberError {
  Invalid(String)
} derive(Debug)

///|
fn digits(financial : Bool) -> Array[String] {
  if financial {
    ["零", "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖"]
  } else {
    ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
  }
}

///|
fn group(n : Int, financial : Bool) -> String {
  let names = digits(financial)
  let units = if financial {
    ["", "拾", "佰", "仟"]
  } else {
    ["", "十", "百", "千"]
  }
  let mut result = ""
  let mut zero = false
  let powers = [1000, 100, 10, 1]
  for i in 0..<4 {
    let d = n / powers[i] % 10
    if d == 0 {
      if result != "" {
        zero = true
      }
    } else {
      if zero {
        result += "零"
        zero = false
      }
      result += names[d] + units[3 - i]
    }
  }
  result
}

///|
/// Range: -9,999,999,999,999,999 through +9,999,999,999,999,999.
pub fn format_integer(
  n : Int64,
  financial? : Bool = false,
) -> String raise NumberError {
  if n < -9999999999999999L || n > 9999999999999999L {
    raise Invalid("integer outside supported range")
  }
  if n == 0L {
    return "零"
  }
  let value = if n < 0L { -n } else { n }
  let powers = [1000000000000L, 100000000L, 10000L, 1L]
  let units = ["兆", "亿", "万", ""]
  let mut out = ""
  let mut skipped = false
  for i in 0..<4 {
    let part = (value / powers[i] % 10000L).to_int()
    if part == 0 {
      if out != "" {
        skipped = true
      }
    } else {
      if out != "" && (skipped || part < 1000) {
        out += "零"
      }
      out += group(part, financial) + units[i]
      skipped = false
    }
  }
  if !financial && out.has_prefix("一十") {
    out = out[1:].to_owned()
  }
  (if n < 0L { "负" } else { "" }) + out
}

///|
fn normalize(s : String) -> String {
  let mut out = ""
  for c in s.iter() {
    out += match c {
      '壹' => "一"
      '贰' => "二"
      '叁' => "三"
      '肆' => "四"
      '伍' => "五"
      '陆' => "六"
      '柒' => "七"
      '捌' => "八"
      '玖' => "九"
      '拾' => "十"
      '佰' => "百"
      '仟' => "千"
      _ => c.to_string()
    }
  }
  out
}

///|
/// Parses canonical output of format_integer (common or financial).
/// Ambiguous colloquialisms such as 一万二 and serial digits 一二三 are rejected.
pub fn parse_integer(
  text : String,
  variants? : Bool = false,
) -> Int64 raise NumberError {
  if text == "" || text.length() > 128 {
    raise Invalid("invalid length")
  }
  let s = normalize(if variants { numeral_variants(text) } else { text })
  let neg = s.has_prefix("负")
  let body = if neg { s[1:].to_owned() } else { s }
  let mut total = 0L
  let mut section = 0L
  let mut digit = 0L
  let mut previous_big = 10000000000000000L
  for c in body.iter() {
    let d = match c {
      '零' => 0
      '一' => 1
      '二' => 2
      '三' => 3
      '四' => 4
      '五' => 5
      '六' => 6
      '七' => 7
      '八' => 8
      '九' => 9
      _ => -1
    }
    if d >= 0 {
      digit = d.to_int64()
      continue
    }
    let unit = match c {
      '十' => 10L
      '百' => 100L
      '千' => 1000L
      '万' => 10000L
      '亿' => 100000000L
      '兆' => 1000000000000L
      _ => raise Invalid("unknown numeral")
    }
    if unit < 10000L {
      section += (if digit == 0L { 1L } else { digit }) * unit
    } else {
      if unit >= previous_big {
        raise Invalid("invalid group order")
      }
      previous_big = unit
      if section + digit > 9999L {
        raise Invalid("group overflow")
      }
      total += (section + digit) * unit
      section = 0L
    }
    digit = 0L
  }
  let value = (total + section + digit) * (if neg { -1L } else { 1L })
  let normal = normalize(format_integer(value))
  let finance = normalize(format_integer(value, financial=true))
  if s != normal && s != finance {
    raise Invalid("noncanonical or ambiguous numeral")
  }
  value
}
