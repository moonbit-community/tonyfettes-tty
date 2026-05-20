///|
const Esc : Byte = b'\x1b'

///|
const EventReaderBufferSize : Int = 8

///|
struct EventReader {
  reader : &@io.Reader
  data : FixedArray[Byte]
  mut head : Int
  mut tail : Int
}

///|
pub fn EventReader::new(reader : &@io.Reader) -> EventReader {
  EventReader::{
    reader,
    data: FixedArray::make(EventReaderBufferSize, b'\x00'),
    head: 0,
    tail: 0,
  }
}

///|
pub async fn EventReader::read_event(
  self : EventReader,
  esc_timeout? : Int = 50,
) -> Event {
  guard self.read_byte() is Some(byte) else { abort("unreachable") }
  if byte == Esc {
    let buffer = @buffer.new()
    buffer.write_byte(Esc)
    read_escape(self, buffer, esc_timeout)
  } else {
    byte_event(byte)
  }
}

///|
async fn EventReader::read_byte(self : EventReader, timeout? : Int) -> Byte? {
  if self.head < self.tail {
    let byte = self.data[self.head]
    self.head += 1
    if self.head == self.tail {
      self.head = 0
      self.tail = 0
    }
    Some(byte)
  } else {
    match timeout {
      Some(timeout) =>
        @async.with_timeout_opt(timeout, () => self.read_byte_raw())
      None => Some(self.read_byte_raw())
    }
  }
}

///|
async fn EventReader::read_byte_raw(self : EventReader) -> Byte {
  self.reader.read_exactly(1)[0]
}

///|
fn EventReader::unread_byte(self : EventReader, byte : Byte) -> Unit {
  if self.tail == self.data.length() {
    let len = self.tail - self.head
    if self.head > 0 {
      self.data.blit_to(self.data, src_offset=self.head, len~)
      self.head = 0
      self.tail = len
    }
  }
  guard self.tail < self.data.length()
  self.data[self.tail] = byte
  self.tail += 1
}

///|
async fn read_escape(
  reader : EventReader,
  buffer : @buffer.Buffer,
  esc_timeout : Int,
) -> Event {
  guard reader.read_byte(timeout=esc_timeout) is Some(byte) else {
    Key(KeyEvent::new(Escape))
  }
  match byte {
    Esc => {
      reader.unread_byte(byte)
      Key(KeyEvent::new(Escape))
    }
    _ => {
      buffer.write_byte(byte)
      read_escape_tail(reader, buffer, byte, esc_timeout)
    }
  }
}

///|
async fn read_escape_tail(
  reader : EventReader,
  buffer : @buffer.Buffer,
  byte : Byte,
  esc_timeout : Int,
) -> Event {
  match byte {
    b'[' => read_csi(reader, buffer, esc_timeout~)
    b'O' => read_ss3(reader, buffer, esc_timeout~)
    0x20..<0x7f as byte =>
      Key(
        KeyEvent::new(
          Char(byte.to_char()),
          modifiers=KeyModifiers::new(alt=true),
        ),
      )
    byte => Unknown([Esc, byte])
  }
}

///|
async fn read_ss3(
  reader : EventReader,
  buffer : @buffer.Buffer,
  esc_timeout~ : Int,
) -> Event {
  guard reader.read_byte(timeout=esc_timeout) is Some(byte) else {
    return Unknown(buffer.to_bytes())
  }
  if byte == Esc {
    reader.unread_byte(byte)
    return Unknown(buffer.to_bytes())
  }
  buffer.write_byte(byte)
  ss3_event(buffer.to_bytes())
}

///|
async fn read_csi(
  reader : EventReader,
  buffer : @buffer.Buffer,
  esc_timeout~ : Int,
) -> Event {
  let mut seen_intermediate = false
  for ;; {
    guard reader.read_byte(timeout=esc_timeout) is Some(byte) else {
      let bytes = buffer.to_bytes()
      return match bytes {
        [Esc, b'['] =>
          Key(KeyEvent::new(Char('['), modifiers=KeyModifiers::new(alt=true)))
        _ => Unknown(bytes)
      }
    }
    buffer.write_byte(byte)
    match byte {
      0x30..<0x40 if seen_intermediate => break Unknown(buffer.to_bytes())
      0x30..<0x40 => ()
      0x20..<0x30 => seen_intermediate = true
      0x40..<0x7f => break csi_event(buffer.to_bytes())
      _ => break Unknown(buffer.to_bytes())
    }
  }
}

///|
fn ss3_event(ss3 : Bytes) -> Event {
  match ss3 {
    [Esc, b'O', b'A'] => Key(KeyEvent::new(Up))
    [Esc, b'O', b'B'] => Key(KeyEvent::new(Down))
    [Esc, b'O', b'C'] => Key(KeyEvent::new(Right))
    [Esc, b'O', b'D'] => Key(KeyEvent::new(Left))
    [Esc, b'O', b'H'] => Key(KeyEvent::new(Home))
    [Esc, b'O', b'F'] => Key(KeyEvent::new(End))
    [Esc, b'O', b'P'] => Key(KeyEvent::new(F1))
    [Esc, b'O', b'Q'] => Key(KeyEvent::new(F2))
    [Esc, b'O', b'R'] => Key(KeyEvent::new(F3))
    [Esc, b'O', b'S'] => Key(KeyEvent::new(F4))
    _ => Unknown(ss3)
  }
}

///|
fn csi_event(csi : Bytes) -> Event {
  match csi {
    [Esc, b'[', b'A'] => Key(KeyEvent::new(Up))
    [Esc, b'[', b'B'] => Key(KeyEvent::new(Down))
    [Esc, b'[', b'C'] => Key(KeyEvent::new(Right))
    [Esc, b'[', b'D'] => Key(KeyEvent::new(Left))
    [Esc, b'[', b'H'] => Key(KeyEvent::new(Home))
    [Esc, b'[', b'F'] => Key(KeyEvent::new(End))
    [Esc, b'[', b'Z'] =>
      Key(KeyEvent::new(Tab, modifiers=KeyModifiers::new(shift=true)))
    [Esc, b'[', b'2', b'~'] => Key(KeyEvent::new(Insert))
    [Esc, b'[', b'3', b'~'] => Key(KeyEvent::new(Delete))
    [Esc, b'[', b'5', b'~'] => Key(KeyEvent::new(PageUp))
    [Esc, b'[', b'6', b'~'] => Key(KeyEvent::new(PageDown))
    _ => csi_param_event(csi).unwrap_or(Unknown(csi))
  }
}

///|
fn csi_param_event(csi : Bytes) -> Event? {
  guard csi.length() >= 3 && csi[0] == Esc && csi[1] == b'[' else {
    return None
  }
  let final_byte = csi[csi.length() - 1]
  guard parse_csi_params(csi, start=2, end=csi.length() - 1) is Some(params) else {
    return None
  }
  match final_byte {
    b'A' => csi_initial_event(params, Up)
    b'B' => csi_initial_event(params, Down)
    b'C' => csi_initial_event(params, Right)
    b'D' => csi_initial_event(params, Left)
    b'H' => csi_initial_event(params, Home)
    b'F' => csi_initial_event(params, End)
    b'P' => csi_initial_event(params, F1)
    b'Q' => csi_initial_event(params, F2)
    b'R' => csi_initial_event(params, F3)
    b'S' => csi_initial_event(params, F4)
    b'~' => csi_tilde_event(params)
    _ => None
  }
}

///|
fn parse_csi_params(csi : Bytes, start~ : Int, end~ : Int) -> Array[Int?]? {
  let params : Array[Int?] = []
  if start == end {
    return Some(params)
  }
  let mut value = 0
  let mut seen = false
  for i = start; i < end; {
    let byte = csi[i]
    match byte {
      b'0'..=b'9' => {
        seen = true
        value = value * 10 + byte.to_int() - b'0'.to_int()
        continue i + 1
      }
      b';' => {
        params.push(if seen { Some(value) } else { None })
        value = 0
        seen = false
        continue i + 1
      }
      _ => return None
    }
  }
  params.push(if seen { Some(value) } else { None })
  Some(params)
}

///|
fn csi_initial_event(params : Array[Int?], code : KeyCode) -> Event? {
  match csi_initial_modifiers(params) {
    Some(modifiers) => Some(Key(KeyEvent::new(code, modifiers~)))
    None => None
  }
}

///|
fn csi_initial_modifiers(params : Array[Int?]) -> KeyModifiers? {
  match params.length() {
    0 => Some(KeyModifiers::new())
    1 =>
      match params[0] {
        None | Some(1) => Some(KeyModifiers::new())
        _ => None
      }
    2 =>
      match params[0] {
        None | Some(1) =>
          match params[1] {
            Some(modifier) => Some(modifiers_from_param(modifier))
            None => Some(KeyModifiers::new())
          }
        _ => None
      }
    _ => None
  }
}

///|
fn csi_tilde_event(params : Array[Int?]) -> Event? {
  guard params.length() == 1 || params.length() == 2 else { return None }
  guard params[0] is Some(code) else { return None }
  let modifiers = if params.length() == 2 {
    match params[1] {
      Some(modifier) => modifiers_from_param(modifier)
      None => KeyModifiers::new()
    }
  } else {
    KeyModifiers::new()
  }
  match tilde_key_code(code) {
    Some(key_code) => Some(Key(KeyEvent::new(key_code, modifiers~)))
    None => None
  }
}

///|
fn tilde_key_code(code : Int) -> KeyCode? {
  match code {
    1 | 7 => Some(Home)
    2 => Some(Insert)
    3 => Some(Delete)
    4 | 8 => Some(End)
    5 => Some(PageUp)
    6 => Some(PageDown)
    11 => Some(F1)
    12 => Some(F2)
    13 => Some(F3)
    14 => Some(F4)
    15 => Some(F5)
    17 => Some(F6)
    18 => Some(F7)
    19 => Some(F8)
    20 => Some(F9)
    21 => Some(F10)
    23 => Some(F11)
    24 => Some(F12)
    _ => None
  }
}

///|
fn modifiers_from_param(param : Int) -> KeyModifiers {
  let bits = param - 1
  if bits <= 0 {
    KeyModifiers::new()
  } else {
    KeyModifiers::new(
      shift=(bits & 1) != 0,
      alt=(bits & 2) != 0,
      ctrl=(bits & 4) != 0,
      meta=(bits & 8) != 0,
    )
  }
}

///|
fn byte_event(byte : Byte) -> Event {
  match byte {
    b'\r' => Key(KeyEvent::new(Enter))
    b'\n' =>
      Key(KeyEvent::new(Char('j'), modifiers=KeyModifiers::new(ctrl=true)))
    b'\t' => Key(KeyEvent::new(Tab))
    b'\x7f' | b'\x08' => Key(KeyEvent::new(Backspace))
    b'\x00' =>
      Key(KeyEvent::new(Char(' '), modifiers=KeyModifiers::new(ctrl=true)))
    0x01..=0x1a =>
      Key(
        KeyEvent::new(
          Char((byte.to_int() - 1 + 'a'.to_int()).unsafe_to_char()),
          modifiers=KeyModifiers::new(ctrl=true),
        ),
      )
    0x1c..=0x1f =>
      Key(
        KeyEvent::new(
          Char((byte.to_int() - 0x1c + '4'.to_int()).unsafe_to_char()),
          modifiers=KeyModifiers::new(ctrl=true),
        ),
      )
    0x20..<0x7f => {
      let char = byte.to_char()
      Key(KeyEvent::new(Char(char), text=[char]))
    }
    _ => Unknown([byte])
  }
}
