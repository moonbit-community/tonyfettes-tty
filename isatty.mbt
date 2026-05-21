///|
extern "c" fn tty_isatty(fd : @async/types.Fd) -> Int = "moonbit_tty_isatty"

///|
pub fn[T : Fd] isatty(fd : T) -> Bool raise @os_error.OSError {
  let fd = fd.fd()
  let rc = tty_isatty(fd)
  if rc < 0 {
    @os_error.check_errno("isatty")
    false
  } else if rc == 0 {
    false
  } else {
    true
  }
}

///|
pub(open) trait Fd {
  fn fd(Self) -> @async/types.Fd
}

///|
pub impl Fd for @async/types.Fd with fd(self) {
  self
}
