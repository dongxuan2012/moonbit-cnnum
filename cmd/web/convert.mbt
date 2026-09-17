///|
/// All outputs are strings, including exact numeric results beyond JS safe integers.
pub fn convert(
  mode : String,
  source : String,
  financial : Bool,
  variants : Bool,
) -> String {
  try {
    match mode {
      "normal" => @lib.cn2an(source, mode="normal")
      "smart" => @lib.cn2an(source, mode="smart")
      "strict" => @lib.cn2an(source)
      "standard" =>
        @lib.an2cn(source, mode=if financial { "up" } else { "low" })
      "rmb" => @lib.an2cn(source, mode="rmb")
      "text-cn" => @lib.transform(source)
      "text-an" => @lib.transform(source, direction="an2cn")
      "decimal" => @lib.format_decimal(source, financial~)
      "parse-decimal" => @lib.parse_decimal(source, variants~)
      "digits" => @lib.format_digits(source, financial~)
      "parse-digits" => @lib.parse_digits(source, variants~)
      "parse-integer" => @lib.parse_integer(source, variants~).to_string()
      "money" => @lib.format_money(@lib.parse_decimal_cents(source))
      "parse-money" =>
        @lib.format_decimal_cents(@lib.parse_money(source, variants~))
      _ => raise Failure("unknown conversion mode")
    }
  } catch {
    e => "ERROR: " + Repr(e).to_string()
  }
}
