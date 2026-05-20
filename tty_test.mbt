///|
async test "Tty::open() when controlling tty is available" {
  try @tty.Input::open() catch {
    _ => ()
  } noraise {
    ti => ti.close()
  }
  try @tty.Output::open() catch {
    _ => ()
  } noraise {
    to => to.close()
  }
}
