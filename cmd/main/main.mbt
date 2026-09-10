///|
fn main raise {
  println(@lib.format_integer(100010001L))
  println(@lib.format_money(@lib.parse_decimal_cents("12345678.09")))
}
