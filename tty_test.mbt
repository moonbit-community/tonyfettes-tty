///|
async test "Tty::open()" {
  let ti = @tty.Input::open()
  defer ti.close()
  let to = @tty.Output::open()
  defer to.close()
}
