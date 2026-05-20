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
async fn read_csi(
  reader : EventReader,
  buffer : @buffer.Buffer,
  esc_timeout~ : Int,
) -> Event {
  let mut seen_intermediate = false
  for ;; {
    guard reader.read_byte(timeout=esc_timeout) is Some(byte) else {
      return Unknown(buffer.to_bytes())
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
    _ => Unknown(csi)
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
