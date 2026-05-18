///|
extern "c" fn tty_isatty(fd : @async/types.Fd) -> Int = "moonbit_tty_isatty"

///|
suberror TtyError {
  InvalidFd(@async/types.Fd)
}

///|
pub fn isatty(fd : @async/types.Fd) -> Bool raise TtyError {
  let rc = tty_isatty(fd)
  if rc == -2 {
    raise InvalidFd(fd)
  } else if rc == 0 {
    return false
  } else {
    return true
  }
}
