///|
fn input_glyphs(source : String, relaxed : Bool) -> String {
  let out = StringBuilder()
  for c in normalize(numeral_variants(source)).iter() {
    let n = c.to_int()
    out.write_char(
      if n >= 0xff10 && n <= 0xff19 {
        (n - 0xff10 + 48).unsafe_to_char()
      } else {
        match c {
          '．' => '.'
          '－' => '-'
          _ => c
        }
      },
    )
  }
  // Strict spelling deliberately excludes colloquial two and circle zero.
  if !relaxed &&
    (source.contains("两") || source.contains("兩") || source.contains("〇")) {
    return source
  }
  out.to_string()
}

///|
fn cn_digit(c : Char) -> Int {
  match c {
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
}

///|
fn short_group(
  source : String,
  relaxed : Bool,
  colloquial : Bool,
) -> Int64 raise NumberError {
  if source.is_empty() {
    raise Invalid("empty numeral group")
  }
  let cs = source.to_array()
  let mut sum = 0
  let mut pending = -1
  let mut previous = 10000
  let mut zero = false
  for i, c in cs {
    let d = cn_digit(c)
    if d >= 0 {
      if pending >= 0 {
        raise Invalid("adjacent group digits")
      }
      if d == 0 {
        if zero || i == 0 {
          raise Invalid("misplaced zero")
        }
        zero = true
      } else {
        pending = d
      }
      continue
    }
    let unit = match c {
      '十' => 10
      '百' => 100
      '千' => 1000
      _ => raise Invalid("unknown numeral")
    }
    if unit >= previous {
      raise Invalid("units must descend")
    }
    if zero && previous <= unit * 10 {
      raise Invalid("unnecessary zero")
    }
    if !relaxed && previous < 10000 && previous > unit * 10 && !zero {
      raise Invalid("missing zero")
    }
    let digit = if pending >= 0 {
      pending
    } else if unit == 10 && (i == 0 || zero || relaxed) {
      1
    } else {
      raise Invalid("unit needs digit")
    }
    sum += digit * unit
    previous = unit
    pending = -1
    zero = false
  }
  if pending >= 0 {
    if previous > 10 && previous < 10000 && !zero {
      if relaxed && colloquial {
        pending *= previous / 10
      } else {
        raise Invalid("omitted final unit")
      }
    }
    sum += pending
  } else if zero && (!relaxed || previous <= 10) {
    raise Invalid("trailing zero")
  }
  if sum <= 0 || sum > 9999 {
    raise Invalid("invalid numeral group")
  }
  sum.to_int64()
}

///|
fn below_yi(
  source : String,
  relaxed : Bool,
  colloquial : Bool,
) -> Int64 raise NumberError {
  let parts = source.split("万").collect()
  if parts.length() > 2 {
    raise Invalid("repeated wan")
  }
  if parts.length() == 1 {
    return short_group(source, relaxed, colloquial)
  }
  let high = short_group(parts[0].to_owned(), relaxed, false)
  let tail = parts[1].to_owned()
  if tail.is_empty() {
    return high * 10000L
  }
  if tail == "零" && relaxed {
    return high * 10000L
  }
  let leading_zero = tail.has_prefix("零")
  let rest = if leading_zero { tail[1:].to_owned() } else { tail }
  if relaxed &&
    colloquial &&
    !leading_zero &&
    rest.length() == 1 &&
    cn_digit(rest.to_array()[0]) > 0 {
    return high * 10000L + cn_digit(rest.to_array()[0]).to_int64() * 1000L
  }
  if !leading_zero && rest.has_prefix("十") {
    raise Invalid("missing group zero")
  }
  let low = short_group(rest, relaxed, colloquial && !leading_zero)
  if (leading_zero && low >= 1000L) ||
    (!relaxed && !leading_zero && low < 1000L) {
    raise Invalid("invalid wan group separator")
  }
  high * 10000L + low
}

///|
fn unit_integer(source : String, relaxed : Bool) -> Int64 raise NumberError {
  if source.is_empty() {
    raise Invalid("missing integer")
  }
  if source == "零" {
    return 0L
  }
  if source.iter().all(c => cn_digit(c) >= 0) {
    if !relaxed && source.length() != 1 {
      raise Invalid("serial digits need normal mode")
    }
    let mut value = 0L
    for c in source.iter() {
      let digit = cn_digit(c).to_int64()
      if value > (9999999999999999L - digit) / 10L {
        raise Invalid("integer range")
      }
      value = value * 10L + digit
    }
    return value
  }
  let parts = source.split("亿").collect()
  if parts.length() > 2 {
    raise Invalid("repeated yi")
  }
  if parts.length() == 1 {
    return below_yi(source, relaxed, true)
  }
  let high = below_yi(parts[0].to_owned(), relaxed, false)
  let tail = parts[1].to_owned()
  if tail.is_empty() {
    return high * 100000000L
  }
  let leading_zero = tail.has_prefix("零")
  let rest = if leading_zero { tail[1:].to_owned() } else { tail }
  if rest.is_empty() {
    raise Invalid("trailing yi zero")
  }
  let low = below_yi(rest, relaxed, true)
  let cs = rest.to_array()
  let final_ellipsis = relaxed &&
    cs.length() >= 2 &&
    cn_digit(cs[cs.length() - 1]) > 0 &&
    (cs[cs.length() - 2] == '百' || cs[cs.length() - 2] == '千')
  if !leading_zero && !rest.contains("万") && !final_ellipsis {
    raise Invalid("missing yi group zero")
  }
  if leading_zero && low >= 10000000L {
    raise Invalid("unnecessary yi zero")
  }
  high * 100000000L + low
}

///|
fn standard_integer(
  value : Int64,
  financial : Bool,
) -> String raise NumberError {
  if value < 0L || value > 9999999999999999L {
    raise Invalid("integer range")
  }
  if value < 100000000L {
    return format_integer(value, financial~)
  }
  let high = value / 100000000L
  let low = value % 100000000L
  let mut out = format_integer(high, financial~) + "亿"
  if low > 0L {
    if low < 10000000L {
      out += "零"
    }
    let mut tail = format_integer(low, financial~)
    if tail.has_prefix("十") {
      tail = "一" + tail
    }
    out += tail
  }
  out
}

///|
fn ascii_value(source : String) -> Int64 raise NumberError {
  let mut value = 0L
  if source.is_empty() {
    raise Invalid("missing digits")
  }
  for c in source.iter() {
    let d = c.to_int() - 48
    if d < 0 || d > 9 || value > (9999999999999999L - d.to_int64()) / 10L {
      raise Invalid("decimal integer range")
    }
    value = value * 10L + d.to_int64()
  }
  value
}

///|
fn compact_decimal(source : String) -> String {
  let mut out = source
  if out.contains(".") {
    while out.has_suffix("0") {
      out = out[:out.length() - 1].to_owned()
    }
    if out.has_suffix(".") {
      out = out[:out.length() - 1].to_owned()
    }
  }
  if out == "-0" {
    "0"
  } else {
    out
  }
}

///|
/// Exact textual result. normal adds serial digits and final-unit ellipsis;
/// smart also expands Arabic runs and decimal coefficients of a single unit.
pub fn cn2an(
  source : String,
  mode? : String = "strict",
) -> String raise NumberError {
  if !["strict", "normal", "smart", "direct"].contains(mode) {
    raise Invalid("unknown parsing mode")
  }
  if source.is_empty() || source.length() > 256 {
    raise Invalid("number length 1..256")
  }
  let relaxed = mode != "strict"
  let text = input_glyphs(source, relaxed)
  if mode == "direct" {
    let out = StringBuilder()
    for c in text.iter() {
      let d = cn_digit(c)
      if d >= 0 {
        out.write_char((48 + d).unsafe_to_char())
      } else if c == '负' {
        out.write_char('-')
      } else if c == '点' {
        out.write_char('.')
      } else if (c >= '0' && c <= '9') || c == '-' || c == '.' {
        out.write_char(c)
      } else {
        raise Invalid("direct mode accepts digits, sign and point only")
      }
    }
    let result = out.to_string()
    ignore(decimal_parts(result))
    return result
  }
  let negative = text.has_prefix("负") ||
    (mode == "smart" && text.has_prefix("-"))
  let body = if negative { text[1:].to_owned() } else { text }
  if body.is_empty() {
    raise Invalid("missing number")
  }
  if mode == "smart" && body.contains(".") {
    let cs = body.to_array()
    let scale = match cs[cs.length() - 1] {
      '十' => 1
      '百' => 2
      '千' => 3
      '万' => 4
      '亿' => 8
      _ => 0
    }
    let raw = if scale > 0 { body[:body.length() - 1].to_owned() } else { body }
    if raw.has_prefix("-") {
      raise Invalid("multiple signs")
    }
    let (_, whole, fraction) = decimal_parts(raw)
    let f = fraction.unwrap_or("")
    if f.length() > 64 {
      raise Invalid("at most 64 fractional digits")
    }
    let combined = whole +
      f +
      "0".repeat(if scale > f.length() { scale - f.length() } else { 0 })
    let point = whole.length() + scale
    let integer = ascii_value(combined[:point].to_owned()).to_string()
    let result = (if negative { "-" } else { "" }) +
      integer +
      (if point < combined.length() {
        "." + combined[point:].to_owned()
      } else {
        ""
      })
    return compact_decimal(result)
  }
  let expanded = StringBuilder()
  let chars = body.to_array()
  let mut i = 0
  let mut after_point = false
  while i < chars.length() {
    let c = chars[i]
    if c >= '0' && c <= '9' && mode == "smart" {
      let digits = StringBuilder()
      while i < chars.length() && chars[i] >= '0' && chars[i] <= '9' {
        digits.write_char(chars[i])
        i += 1
      }
      let run = digits.to_string()
      expanded.write_string(
        if after_point || (run.length() > 1 && run.has_prefix("0")) {
          format_digits(run)
        } else {
          standard_integer(ascii_value(run), false)
        },
      )
    } else {
      if c == '点' {
        after_point = true
      }
      expanded.write_char(c)
      i += 1
    }
  }
  let parts = expanded.to_string().split("点").collect()
  if parts.length() > 2 {
    raise Invalid("multiple decimal points")
  }
  let whole = unit_integer(parts[0].to_owned(), relaxed)
  let mut out = (if negative { "-" } else { "" }) + whole.to_string()
  if parts.length() == 2 {
    let fraction = parts[1].to_owned()
    if fraction.length() > 64 ||
      (!relaxed && (fraction.is_empty() || fraction.has_suffix("零"))) {
      raise Invalid("invalid fractional spelling")
    }
    if !fraction.is_empty() {
      out += "." + parse_digits(fraction)
    }
  }
  compact_decimal(out)
}

///|
/// Format text using wan/yi groups, keeping exact fraction digits and signed zero.
pub fn an2cn(
  source : String,
  mode? : String = "low",
) -> String raise NumberError {
  if !["low", "up", "rmb", "direct"].contains(mode) {
    raise Invalid("unknown formatting mode")
  }
  let text = input_glyphs(source, true)
  if mode == "direct" {
    if text.is_empty() || text.length() > 256 {
      raise Invalid("number length 1..256")
    }
    let out = StringBuilder()
    let names = digits(false)
    for c in text.iter() {
      if c >= '0' && c <= '9' {
        out.write_string(names[c.to_int() - 48])
      } else if c == '-' {
        out.write_string("负")
      } else if c == '.' {
        out.write_string("点")
      } else {
        raise Invalid("direct mode accepts digits, sign and point only")
      }
    }
    return out.to_string()
  }
  let clean = if text.has_suffix(".") {
    text[:text.length() - 1].to_owned()
  } else {
    text
  }
  if mode == "rmb" {
    return format_currency(clean, rounding="truncate")
  }
  let (negative, whole, fraction) = decimal_parts(clean)
  let financial = mode == "up"
  let mut out = (if negative { "负" } else { "" }) +
    standard_integer(ascii_value(whole), financial)
  if fraction is Some(f) {
    if f.length() > 64 {
      raise Invalid("at most 64 fractional digits")
    }
    out += "点" + format_digits(f, financial~)
  }
  out
}

///|
/// Text arithmetic; rounding is reject (default), truncate, or half-up.
pub fn format_currency(
  source : String,
  zero_yuan? : Bool = false,
  yuan? : String = "元",
  whole_suffix? : String = "整",
  prefix? : String = "",
  rounding? : String = "reject",
  parentheses? : Bool = false,
) -> String raise NumberError {
  if !["reject", "truncate", "half-up"].contains(rounding) {
    raise Invalid("unknown rounding mode")
  }
  if yuan.is_empty() ||
    yuan.length() > 8 ||
    whole_suffix.length() > 8 ||
    prefix.length() > 32 {
    raise Invalid("currency label length")
  }
  let (negative, whole, fraction) = decimal_parts(source)
  let f = fraction.unwrap_or("")
  if f.length() > 64 || (rounding == "reject" && f.length() > 2) {
    raise Invalid("currency requires at most two fractional digits")
  }
  let mut value = ascii_value(whole)
  let cents = f + "00"
  let mut tail = (cents[0].to_int() - 48) * 10 + cents[1].to_int() - 48
  if rounding == "half-up" && f.length() > 2 && f[2].to_int() >= 53 {
    tail += 1
  }
  if tail == 100 {
    value += 1
    tail = 0
  }
  let names = digits(true)
  let mut out = if value > 0L || zero_yuan || tail == 0 {
    standard_integer(value, true) + yuan
  } else {
    ""
  }
  if tail == 0 {
    out += whole_suffix
  } else {
    if tail / 10 > 0 {
      out += names[tail / 10] + "角"
    } else if value > 0L {
      out += "零"
    }
    if tail % 10 > 0 {
      out += names[tail % 10] + "分"
    }
  }
  prefix +
  (if negative {
    if parentheses {
      "（" + out + "）"
    } else {
      "负" + out
    }
  } else {
    out
  })
}
