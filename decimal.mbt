///|
/// Character variants only: no colloquial magnitude inference or text extraction.
fn numeral_variants(source : String) -> String {
  let out = StringBuilder()
  for c in source.iter() {
    out.write_char(
      match c {
        '負' => '负'
        '萬' => '万'
        '億' => '亿'
        '貳' => '贰'
        '參' => '叁'
        '陸' => '陆'
        '兩' | '两' => '二'
        '〇' => '零'
        '點' => '点'
        _ => c
      },
    )
  }
  out.to_string()
}

///|
/// Validate a signed decimal string without floating point or exponent notation.
fn decimal_parts(source : String) -> (Bool, String, String?) raise NumberError {
  if source.is_empty() || source.length() > 256 {
    raise Invalid("decimal length 1..256")
  }
  let negative = source.has_prefix("-")
  let body = if negative { source[1:].to_owned() } else { source }
  let parts = body.split(".").collect()
  if parts.length() > 2 || parts.iter().any(p => p.is_empty()) {
    raise Invalid("decimal requires digits on both sides of the point")
  }
  for part in parts {
    if !part.iter().all(c => c >= '0' && c <= '9') {
      raise Invalid("ASCII decimal digits required")
    }
  }
  (
    negative,
    parts[0].to_owned(),
    if parts.length() == 2 {
      Some(parts[1].to_owned())
    } else {
      None
    },
  )
}

///|
/// Read a digit sequence, retaining leading zeros, fraction scale and negative zero.
pub fn format_digits(
  source : String,
  financial? : Bool = false,
) -> String raise NumberError {
  ignore(decimal_parts(source))
  let names = digits(financial)
  let out = StringBuilder()
  for c in source.iter() {
    out.write_string(
      match c {
        '-' => "负"
        '.' => "点"
        _ => names[c.to_int() - 48]
      },
    )
  }
  out.to_string()
}

///|
/// Direct digit reading: 一二点三零 -> 12.30; unit words such as 十 are rejected.
pub fn parse_digits(
  source : String,
  variants? : Bool = false,
) -> String raise NumberError {
  if source.is_empty() || source.length() > 256 {
    raise Invalid("digit text length 1..256")
  }
  let source = normalize(
    if variants {
      numeral_variants(source)
    } else {
      source
    },
  )
  let names = digits(false)
  let out = StringBuilder()
  for c in source.iter() {
    if c == '负' {
      out.write_char('-')
      continue
    }
    if c == '点' {
      out.write_char('.')
      continue
    }
    let mut digit = -1
    for i, name in names {
      if name == c.to_string() {
        digit = i
        break
      }
    }
    if digit < 0 {
      raise Invalid("expected individual Chinese digit")
    }
    out.write_char((digit + 48).unsafe_to_char())
  }
  let result = out.to_string()
  ignore(decimal_parts(result))
  result
}

///|
/// Unit-based integer part plus up to 64 exact fractional digits. Retains trailing zeros.
/// Leading integer zeros are normalized; explicit negative zero is retained.
pub fn format_decimal(
  source : String,
  financial? : Bool = false,
) -> String raise NumberError {
  let (negative, whole, fraction) = decimal_parts(source)
  let mut value = 0L
  for c in whole.iter() {
    let digit = (c.to_int() - 48).to_int64()
    if value > (9999999999999999L - digit) / 10L {
      raise Invalid("integer outside supported range")
    }
    value = value * 10L + digit
  }
  let mut result = (if negative { "负" } else { "" }) +
    format_integer(value, financial~)
  if fraction is Some(text) {
    if text.length() > 64 {
      raise Invalid("at most 64 fractional digits")
    }
    result += "点" + format_digits(text, financial~)
  }
  result
}

///|
/// Returns an exact ASCII decimal string; never rounds through a floating-point value.
pub fn parse_decimal(
  source : String,
  variants? : Bool = false,
) -> String raise NumberError {
  if source.is_empty() || source.length() > 256 {
    raise Invalid("decimal text length 1..256")
  }
  let source = if variants { numeral_variants(source) } else { source }
  let negative = source.has_prefix("负")
  let body = if negative { source[1:].to_owned() } else { source }
  let parts = body.split("点").collect()
  if parts.length() > 2 ||
    parts.iter().any(p => p.is_empty()) ||
    body.contains("负") {
    raise Invalid("invalid Chinese decimal")
  }
  let whole = parse_integer(parts[0].to_owned())
  let mut result = (if negative { "-" } else { "" }) + whole.to_string()
  if parts.length() == 2 {
    let fraction = parse_digits(parts[1].to_owned())
    if fraction.length() > 64 ||
      fraction.contains("-") ||
      fraction.contains(".") {
      raise Invalid("invalid decimal fraction")
    }
    result += "." + fraction
  }
  result
}

///|
/// Complement of parse_decimal_cents: always exactly two decimal digits.
pub fn format_decimal_cents(cents : Int64) -> String raise NumberError {
  if cents < -9999999999999999L || cents > 9999999999999999L {
    raise Invalid("amount outside supported range")
  }
  let amount = if cents < 0L { -cents } else { cents }
  let fraction = (amount % 100L).to_int()
  (if cents < 0L { "-" } else { "" }) +
  (amount / 100L).to_string() +
  "." +
  (if fraction < 10 { "0" } else { "" }) +
  fraction.to_string()
}
