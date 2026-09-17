///|
extern "js" fn clock_ms() -> Double =
  #|() => performance.now()

///|
fn benchmark_value(operation : String, input : String) -> String raise {
  match operation {
    "parse" => @lib.cn2an(input, mode="normal")
    "format" => @lib.an2cn(input)
    "text-cn" => @lib.transform(input)
    "text-an" => @lib.transform(input, direction="an2cn")
    _ => raise Failure("unknown benchmark group")
  }
}

///|
/// Development timing entry; JSON parsing and result serialization are outside the timer.
pub fn benchmark_json(request : String) -> String {
  try {
    let fields = match @json.parse(request) {
      Object(f) => f
      _ => raise Failure("object required")
    }
    let operation = field_string(fields, "operation", "")
    let inputs : Array[String] = match fields.get("inputs") {
      Some(Array(values)) =>
        values.map(value => {
          match value {
            String(s) => s
            _ => raise Failure("string input required")
          }
        })
      _ => raise Failure("inputs required")
    }
    let iterations = match fields.get("iterations") {
      Some(Number(value, ..)) => value.to_int()
      _ => 0
    }
    if iterations < 1 ||
      iterations > 10000 ||
      inputs.length() < 1 ||
      inputs.length() > 64 {
      raise Failure("benchmark bounds")
    }
    let start = clock_ms()
    let mut length = 0
    for _ in 0..<iterations {
      for input in inputs {
        length += benchmark_value(operation, input).length()
      }
    }
    let elapsed = clock_ms() - start
    let results = inputs.map(input => benchmark_value(operation, input))
    (
      { "ok": true, "elapsedMs": elapsed, "length": length, "results": results } :
      Json).stringify()
  } catch {
    e => ({ "ok": false, "error": Repr(e).to_string() } : Json).stringify()
  }
}
