///|
/// Terminal input handle.
///
/// A `Reader` is an async byte reader that also exposes the terminal file
/// descriptor used by stateful terminal operations.
pub(open) trait Reader: @async/io.Reader + Fd {
  fn close(Self) -> Unit
}

///|
/// Terminal output handle.
///
/// A `Writer` is an async byte writer that also exposes the terminal file
/// descriptor used by output-side terminal queries.
pub(open) trait Writer: @async/io.Writer + Fd {
  fn close(Self) -> Unit
}

///|
pub impl Reader for @async/fs.File with fn close(self) {
  @async/fs.File::close(self)
}

///|
pub impl Writer for @async/fs.File with fn close(self) {
  @async/fs.File::close(self)
}

///|
pub impl Reader for @async/pipe.PipeRead with fn close(self) {
  @async/pipe.PipeRead::close(self)
}

///|
pub impl Writer for @async/pipe.PipeWrite with fn close(self) {
  @async/pipe.PipeWrite::close(self)
}

///|
pub impl Reader for @async/stdio.Input with fn close(_) {
  ()
}

///|
pub impl Writer for @async/stdio.Output with fn close(_) {
  ()
}
