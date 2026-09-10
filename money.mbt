///|
/// Exact signed integer cents; no binary floating-point conversion or rounding.
pub fn format_money(cents : Int64) -> String raise NumberError {
  if cents < -9999999999999999L || cents > 9999999999999999L {
    raise Invalid("amount outside supported range")
  }
  let n = if cents < 0L { -cents } else { cents }
  let names = digits(true)
  let mut out = (if cents < 0L { "负" } else { "" }) +
    format_integer(n / 100L, financial=true) +
    "元"
  let jiao = (n / 10L % 10L).to_int()
  let fen = (n % 10L).to_int()
  if jiao == 0 && fen == 0 {
    return out + "整"
  }
  if jiao > 0 {
    out += names[jiao] + "角"
  } else if n >= 100L {
    out += "零"
  }
  if fen > 0 {
    out += names[fen] + "分"
  }
  out
}

///|
pub fn parse_decimal_cents(s : String) -> Int64 raise NumberError {
  if s == "" || s.length() > 32 {
    raise Invalid("invalid amount")
  }
  let neg = s.has_prefix("-")
  let mut whole = 0L
  let mut fraction = 0L
  let mut count = 0
  let mut point = false
  let mut whole_digits = 0
  for i in (if neg { 1 } else { 0 })..<s.length() {
    let c = s[i].to_int()
    if c == 46 {
      if point || whole_digits == 0 {
        raise Invalid("invalid decimal point")
      }
      point = true
    } else {
      if c < 48 || c > 57 {
        raise Invalid("invalid decimal digit")
      }
      if point {
        count += 1
        if count > 2 {
          raise Invalid("more than two fractional digits")
        }
        fraction = fraction * 10L + (c - 48).to_int64()
      } else {
        whole_digits += 1
        whole = whole * 10L + (c - 48).to_int64()
        if whole > 99999999999999L {
          raise Invalid("amount overflow")
        }
      }
    }
  }
  if whole_digits == 0 || (point && count == 0) {
    raise Invalid("missing digits")
  }
  if count == 1 {
    fraction *= 10L
  }
  (whole * 100L + fraction) * (if neg { -1L } else { 1L })
}
