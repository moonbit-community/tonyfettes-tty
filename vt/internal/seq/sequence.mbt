///|
const Esc : Byte = b'\x1b'

///|
fn count_decimal_digits(n : Int) -> Int {
  guard n >= 0 else {
    abort(
      "@tonyfettes/tty/vt/internal/seq.count_decimal_digits: n should be greater or equal to 0",
    )
  }
  for len = 1, val = n; val >= 10; val = val / 10, len = len + 1 {

  } nobreak {
    len
  }
}

///|
fn write_decimal_digits(
  buf : FixedArray[Byte],
  n : Int,
  offset? : Int = 0,
  length? : Int = count_decimal_digits(n),
) -> Int {
  let mut value = n
  for i in 0..<length {
    let index = offset + length - i - 1
    buf[index] = (value % 10 + b'0'.to_int()).to_byte()
    value = value / 10
  }
  offset + length
}

///|
pub fn csi1(n : Int, final_byte : Byte) -> Bytes {
  let len = count_decimal_digits(n)
  let buf : FixedArray[Byte] = FixedArray::make(3 + len, 0)
  buf[0] = Esc
  buf[1] = b'['
  let offset = write_decimal_digits(buf, n, offset=2, length=len)
  buf[offset] = final_byte
  buf.unsafe_reinterpret_as_bytes()
}

///|
pub fn csi2(n1 : Int, n2 : Int, final_byte : Byte) -> Bytes {
  let len1 = count_decimal_digits(n1)
  let len2 = count_decimal_digits(n2)
  let buf : FixedArray[Byte] = FixedArray::make(4 + len1 + len2, 0)
  buf[0] = Esc
  buf[1] = b'['
  let offset = write_decimal_digits(buf, n1, offset=2, length=len1)
  buf[offset] = b';'
  let offset = write_decimal_digits(buf, n2, offset=offset + 1, length=len2)
  buf[offset] = final_byte
  buf.unsafe_reinterpret_as_bytes()
}

///|
pub fn sgr1(p1 : Int) -> Bytes {
  csi1(p1, b'm')
}

///|
pub fn sgr3(p1 : Int, p2 : Int, p3 : Int) -> Bytes {
  let len1 = count_decimal_digits(p1)
  let len2 = count_decimal_digits(p2)
  let len3 = count_decimal_digits(p3)
  let buf : FixedArray[Byte] = FixedArray::make(5 + len1 + len2 + len3, 0)
  buf[0] = Esc
  buf[1] = b'['
  let offset = write_decimal_digits(buf, p1, offset=2, length=len1)
  buf[offset] = b';'
  let offset = write_decimal_digits(buf, p2, offset=offset + 1, length=len2)
  buf[offset] = b';'
  let offset = write_decimal_digits(buf, p3, offset=offset + 1, length=len3)
  buf[offset] = b'm'
  buf.unsafe_reinterpret_as_bytes()
}

///|
pub fn sgr5(p1 : Int, p2 : Int, p3 : Int, p4 : Int, p5 : Int) -> Bytes {
  let len1 = count_decimal_digits(p1)
  let len2 = count_decimal_digits(p2)
  let len3 = count_decimal_digits(p3)
  let len4 = count_decimal_digits(p4)
  let len5 = count_decimal_digits(p5)
  let buf : FixedArray[Byte] = FixedArray::make(
    7 + len1 + len2 + len3 + len4 + len5,
    0,
  )
  buf[0] = Esc
  buf[1] = b'['
  let offset = write_decimal_digits(buf, p1, offset=2, length=len1)
  buf[offset] = b';'
  let offset = write_decimal_digits(buf, p2, offset=offset + 1, length=len2)
  buf[offset] = b';'
  let offset = write_decimal_digits(buf, p3, offset=offset + 1, length=len3)
  buf[offset] = b';'
  let offset = write_decimal_digits(buf, p4, offset=offset + 1, length=len4)
  buf[offset] = b';'
  let offset = write_decimal_digits(buf, p5, offset=offset + 1, length=len5)
  buf[offset] = b'm'
  buf.unsafe_reinterpret_as_bytes()
}
