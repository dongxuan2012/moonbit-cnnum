///|
pub fn run(input : String) -> String {
  try {
    let cents = @lib.parse_decimal_cents(input.trim().to_owned())
    @lib.format_money(cents) + "\nExact cents: " + cents.to_string()
  } catch {
    e => "ERROR: " + Repr(e).to_string()
  }
}

///|
fn main {

}
