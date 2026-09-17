///|
fn field_string(
  fields : Map[String, Json],
  name : String,
  fallback : String,
) -> String raise {
  match fields.get(name) {
    Some(String(value)) => value
    None => fallback
    _ => raise Failure(name + " must be a string")
  }
}

///|
fn field_bool(
  fields : Map[String, Json],
  name : String,
  fallback : Bool,
) -> Bool raise {
  match fields.get(name) {
    Some(True) => true
    Some(False) => false
    None => fallback
    _ => raise Failure(name + " must be boolean")
  }
}

///|
pub fn convert_json(request : String) -> String {
  try {
    if request.length() > 2097152 {
      raise Failure("request length limit")
    }
    let fields = match @json.parse(request) {
      Object(fields) => fields
      _ => raise Failure("object required")
    }
    let operation = field_string(fields, "operation", "cn2an")
    let source = field_string(fields, "input", "")
    let mode = field_string(
      fields,
      "mode",
      if operation == "cn2an" {
        "strict"
      } else {
        "low"
      },
    )
    let direction = field_string(fields, "direction", "cn2an")
    let direct = field_bool(fields, "direct", false)
    let result : Json = match operation {
      "cn2an" => Json::string(@lib.cn2an(source, mode~))
      "an2cn" => Json::string(@lib.an2cn(source, mode~))
      "transform" => Json::string(@lib.transform(source, direction~, direct~))
      "spans" =>
        Json::array(
          @lib.transform_spans(source, direction~, direct~).map(span => {
            (
              {
                "start": span.start,
                "end": span.end,
                "kind": span.kind,
                "source": span.source,
                "replacement": span.replacement,
              } : Json)
          }),
        )
      "currency" =>
        Json::string(
          @lib.format_currency(
            source,
            zero_yuan=field_bool(fields, "zeroYuan", false),
            yuan=field_string(fields, "yuan", "元"),
            whole_suffix=field_string(fields, "wholeSuffix", "整"),
            prefix=field_string(fields, "prefix", ""),
            rounding=field_string(fields, "rounding", "reject"),
            parentheses=field_bool(fields, "parentheses", false),
          ),
        )
      _ => raise Failure("unknown operation")
    }
    ({ "ok": true, "result": result } : Json).stringify()
  } catch {
    e => ({ "ok": false, "error": Repr(e).to_string() } : Json).stringify()
  }
}
