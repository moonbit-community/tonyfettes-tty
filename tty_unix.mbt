///|
pub async fn Input::open() -> Input {
  File(@async/fs.open("/dev/tty", mode=ReadOnly))
}

///|
pub async fn Output::open() -> Output {
  File(@async/fs.open("/dev/tty", mode=WriteOnly))
}
