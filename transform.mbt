///|
/// Offsets are UTF-16 code units, matching String slicing and browser selection.
pub struct NumberSpan {
  start : Int
  end : Int
  kind : String
  source : String
  replacement : String
} derive(Debug, Eq)

///|
fn text_at(text : String, start : Int, needle : String) -> Bool {
  if start + needle.length() > text.length() {
    return false
  }
  for j in 0..<needle.length() {
    if text[start + j] != needle[j] {
      return false
    }
  }
  true
}

///|
fn ascii_digit_at(text : String, i : Int) -> Bool {
  if i >= text.length() {
    return false
  }
  let c = text[i].to_int()
  (c >= 48 && c <= 57) || (c >= 0xff10 && c <= 0xff19)
}

///|
fn number_end(text : String, start : Int, chinese : Bool) -> Int {
  let mut i = start
  let mut point = false
  while i < text.length() {
    let c = text[i].to_int().unsafe_to_char()
    if ascii_digit_at(text, i) {
      i += 1
      continue
    }
    if (c == '-' || c == '－' || (chinese && (c == '负' || c == '負'))) &&
      i == start {
      if (c == '-' || c == '－') &&
        start > 0 &&
        ascii_digit_at(text, start - 1) {
        break
      }
      if i + 1 < text.length() {
        i += 1
        continue
      }
    }
    if c == '.' || c == '．' || (chinese && (c == '点' || c == '點')) {
      if point || i == start {
        break
      }
      point = true
      i += 1
      continue
    }
    if chinese &&
      "零〇一二两兩三四五六七八九十百千万亿壹贰貳叁參肆伍陆陸柒捌玖拾佰仟萬億".contains(
        c.to_string(),
      ) {
      i += 1
      continue
    }
    break
  }
  while i > start &&
        (text[i - 1].to_int() == 46 || text[i - 1].to_int() == 0xff0e) {
    i -= 1
  }
  i
}

///|
fn sentence_value(
  text : String,
  chinese : Bool,
  direct : Bool,
) -> String raise NumberError {
  if chinese {
    cn2an(text, mode=if direct { "direct" } else { "smart" })
  } else {
    an2cn(text, mode=if direct { "direct" } else { "low" })
  }
}

///|
fn conversion_span(
  text : String,
  start : Int,
  chinese : Bool,
  direct : Bool,
) -> NumberSpan? raise NumberError {
  // A hyphen between Arabic runs is a separator, not a unary minus.
  if start > 0 && text_at(text, start, "-") && ascii_digit_at(text, start - 1) {
    return None
  }
  let below_zero = chinese && !direct && text_at(text, start, "零下")
  let negative_percent = chinese &&
    !direct &&
    text_at(text, start, "负百分之")
  let percent = chinese &&
    !direct &&
    (text_at(text, start, "百分之") || negative_percent)
  let begin = start +
    (if below_zero {
      2
    } else if negative_percent {
      4
    } else if percent {
      3
    } else {
      0
    })
  let end = number_end(text, begin, chinese)
  if end == begin || end - begin > 256 {
    return None
  }
  let original = text[begin:end].to_owned()
  if chinese &&
    !original.iter().any(c => c.to_int() > 127 && c.to_int() < 0xff00) &&
    !percent &&
    !below_zero {
    return None
  }
  let first = sentence_value(original, chinese, direct)
  let mut replacement = first
  let mut finish = end
  let mut kind = if direct { "direct" } else { "number" }
  if !direct {
    if percent {
      replacement = (if negative_percent { "负" } else { "" }) + first + "%"
      kind = "percent"
    } else if chinese && text_at(text, end, "摄氏度") {
      replacement = (if below_zero { "-" } else { "" }) + first + "℃"
      finish += 3
      kind = "temperature"
    } else if below_zero {
      return None
    } else if !chinese &&
      (text_at(text, end, "℃") || text_at(text, end, "°C")) {
      replacement += "摄氏度"
      finish += if text_at(text, end, "℃") { 1 } else { 2 }
      kind = "temperature"
    } else if !chinese && (text_at(text, end, "%") || text_at(text, end, "％")) {
      replacement = "百分之" + first
      finish += 1
      kind = "percent"
    } else if text_at(text, end, if chinese { "分之" } else { "/" }) {
      let second_start = end + (if chinese { 2 } else { 1 })
      let second_end = number_end(text, second_start, chinese)
      if second_end > second_start {
        let second = sentence_value(
          text[second_start:second_end].to_owned(),
          chinese,
          false,
        )
        replacement = second + (if chinese { "/" } else { "分之" }) + first
        finish = second_end
        kind = "fraction"
      }
    } else if !chinese &&
      text_at(text, end, "年") &&
      original.length() >= 2 &&
      original.length() <= 4 &&
      !original.contains(".") &&
      !original.contains("-") {
      replacement = an2cn(original, mode="direct")
      kind = "date-year"
    } else if !chinese &&
      text_at(text, end, "-") &&
      ascii_digit_at(text, end + 1) {
      let second_end = number_end(text, end + 1, false)
      replacement = first + "到" + an2cn(text[end + 1:second_end].to_owned())
      finish = second_end
      kind = "range"
    }
  }
  Some({
    start,
    end: finish,
    kind,
    source: text[start:finish].to_owned(),
    replacement,
  })
}

///|
/// Deterministic lexical conversion, not language understanding. Invalid maximal
/// numeral runs are preserved as a whole. Input limit: 262144 UTF-16 code units.
pub fn transform_spans(
  source : String,
  direction? : String = "cn2an",
  direct? : Bool = false,
) -> Array[NumberSpan] raise NumberError {
  if direction != "cn2an" && direction != "an2cn" {
    raise Invalid("unknown transform direction")
  }
  if source.length() > 262144 {
    raise Invalid("sentence length limit")
  }
  let chinese = direction == "cn2an"
  let spans : Array[NumberSpan] = []
  let mut i = 0
  while i < source.length() {
    let candidate = conversion_span(source, i, chinese, direct) catch {
      _ => None
    }
    if candidate is Some(span) {
      spans.push(span)
      i = span.end
    } else {
      let end = number_end(source, i, chinese)
      i = if end > i { end } else { i + 1 }
    }
  }
  spans
}

///|
pub fn transform(
  source : String,
  direction? : String = "cn2an",
  direct? : Bool = false,
) -> String raise NumberError {
  let spans = transform_spans(source, direction~, direct~)
  let out = StringBuilder()
  let mut start = 0
  for span in spans {
    out.write_string(source[start:span.start].to_owned())
    out.write_string(span.replacement)
    start = span.end
  }
  out.write_string(source[start:].to_owned())
  out.to_string()
}
