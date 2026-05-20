///|
let prompt : String = "> "

///|
let esc_timeout_ms : Int = 50

///|
async fn writeln(line : String) -> Unit {
  @tty.stdout.write(line)
  @tty.stdout.write("\r\n")
}

///|
async fn redraw_input(buffer : Array[Byte], status : String) -> Unit {
  @tty.stdout.write("\r")
  @tty.stdout.write(@tty/vt.erase_line_all)
  @tty.stdout.write(prompt)
  @tty.stdout.write(Bytes::from_array(buffer))
  if status.length() > 0 {
    let suffix = "  \{status}"
    @tty.stdout.write(suffix)
    @tty.stdout.write(@tty/vt.cursor_back(suffix.length()))
  }
}

///|
fn ascii_bytes_to_string(buffer : Array[Byte]) -> String {
  let builder = StringBuilder(size_hint=buffer.length())
  for byte in buffer {
    builder.write_char(byte.to_char())
  }
  builder.to_string()
}

///|
async fn submit(buffer : Array[Byte]) -> Unit {
  let line = ascii_bytes_to_string(buffer)
  @tty.stdout.write("\r")
  @tty.stdout.write(@tty/vt.erase_line_all)
  writeln("\{prompt}\{line}")
  writeln("submitted: \{line}")
  buffer.clear()
  redraw_input(buffer, "submitted")
}

///|
fn printable_ascii_byte(ch : Char) -> Byte? {
  let code = ch.to_int()
  if code >= 0x20 && code < 0x7f {
    Some(code.to_byte())
  } else {
    None
  }
}

///|
fn byte_to_hex(byte : Byte) -> String {
  let digits : ReadOnlyArray[Char] = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f',
  ]
  ['0', 'x', digits[byte.to_int() / 16], digits[byte.to_int() % 16]]
}

///|
fn describe_bytes(bytes : Bytes) -> String {
  let builder = StringBuilder()
  for i in 0..<bytes.length() {
    if i > 0 {
      builder.write_string(" ")
    }
    builder.write_string(byte_to_hex(bytes[i]))
  }
  builder.to_string()
}

///|
fn push_printable_ascii_text(buffer : Array[Byte], text : String) -> Unit {
  text
  .iter()
  .each(ch => if printable_ascii_byte(ch) is Some(byte) { buffer.push(byte) })
}

///|
fn describe_modifiers(modifiers : @tty/input.KeyModifiers) -> String {
  let builder = StringBuilder()
  if modifiers.ctrl() {
    builder.write_string("Ctrl+")
  }
  if modifiers.alt() {
    builder.write_string("Alt+")
  }
  if modifiers.shift() {
    builder.write_string("Shift+")
  }
  if modifiers.meta() {
    builder.write_string("Meta+")
  }
  builder.to_string()
}

///|
fn describe_key(key : @tty/input.KeyEvent) -> String {
  let modifier = describe_modifiers(key.modifiers)
  let name = match key.code {
    @tty/input.Char(ch) => "\{ch}"
    @tty/input.Text => "Text"
    @tty/input.Enter => "Enter"
    @tty/input.Tab => "Tab"
    @tty/input.Backspace => "Backspace"
    @tty/input.Delete => "Delete"
    @tty/input.Escape => "Escape"
    @tty/input.Up => "Up"
    @tty/input.Down => "Down"
    @tty/input.Left => "Left"
    @tty/input.Right => "Right"
    @tty/input.Home => "Home"
    @tty/input.End => "End"
    @tty/input.PageUp => "PageUp"
    @tty/input.PageDown => "PageDown"
    @tty/input.Insert => "Insert"
    @tty/input.F1 => "F1"
    @tty/input.F2 => "F2"
    @tty/input.F3 => "F3"
    @tty/input.F4 => "F4"
    @tty/input.F5 => "F5"
    @tty/input.F6 => "F6"
    @tty/input.F7 => "F7"
    @tty/input.F8 => "F8"
    @tty/input.F9 => "F9"
    @tty/input.F10 => "F10"
    @tty/input.F11 => "F11"
    @tty/input.F12 => "F12"
  }
  "event: Key \{modifier}\{name}"
}

///|
async fn run_input_buffer() -> Unit {
  let events = @tty.stdin.event_reader()
  let buffer : Array[Byte] = []
  writeln("input buffer demo")
  writeln(
    "Type printable ASCII. Enter submits. Backspace deletes. Esc uses a \{esc_timeout_ms}ms timeout. Ctrl-C exits.",
  )
  redraw_input(buffer, "")
  while true {
    let event = events.read_event(esc_timeout=esc_timeout_ms) catch {
      @async/io.ReaderClosed => break
      error => raise error
    }
    match event {
      Key(key) =>
        match key.code {
          Char('c') if key.modifiers.ctrl() => {
            @tty.stdout.write("\r")
            @tty.stdout.write(@tty/vt.erase_line_all)
            writeln("exiting")
            break
          }
          Enter => submit(buffer)
          Backspace => {
            ignore(buffer.pop())
            redraw_input(buffer, "event: Backspace")
          }
          Char(ch) if !key.modifiers.ctrl() && !key.modifiers.alt() => {
            match key.text {
              Some(text) => push_printable_ascii_text(buffer, text)
              None =>
                if printable_ascii_byte(ch) is Some(byte) {
                  buffer.push(byte)
                }
            }
            redraw_input(buffer, describe_key(key))
          }
          _ => redraw_input(buffer, describe_key(key))
        }
      @tty/input.Unknown(bytes) =>
        redraw_input(
          buffer,
          "event: Unknown \{bytes.length()} bytes [\{describe_bytes(bytes)}]",
        )
    }
  }
}

///|
async fn main {
  @tty.stdin.with_raw_mode(run_input_buffer)
}
