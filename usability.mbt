///|
/// Parse the canonical output of format_money, including financial digits.
pub fn parse_money(source : String) -> Int64 raise NumberError {
  if source.length() > 100 {
    raise Invalid("amount text too long")
  }
  let negative = source.has_prefix("负")
  let s = if negative { source[1:].to_owned() } else { source }
  let parts = s.split("元").collect()
  if parts.length() != 2 {
    raise Invalid("expected yuan separator")
  }
  let whole = parse_integer(parts[0].to_owned())
  if whole < 0L || whole > 99999999999999L {
    raise Invalid("whole amount range")
  }
  let tail = parts[1].to_owned()
  let mut fraction = 0
  if tail != "整" {
    let cs = tail.to_array()
    let mut i = if cs.length() > 0 && cs[0] == '零' { 1 } else { 0 }
    let names = digits(true)
    while i < cs.length() {
      if i + 1 >= cs.length() {
        raise Invalid("fraction unit missing")
      }
      let mut value = -1
      for n in 1..<10 {
        if names[n] == cs[i].to_string() {
          value = n
        }
      }
      if value < 1 {
        raise Invalid("fraction digit")
      }
      if cs[i + 1] == '角' {
        fraction += value * 10
      } else if cs[i + 1] == '分' {
        fraction += value
      } else {
        raise Invalid("fraction unit")
      }
      i += 2
    }
  }
  let amount = (whole * 100L + fraction.to_int64()) *
    (if negative { -1L } else { 1L })
  if format_money(amount) != source {
    raise Invalid("noncanonical financial amount")
  }
  amount
}
