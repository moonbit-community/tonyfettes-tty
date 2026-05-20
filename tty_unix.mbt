///|
/// Open the controlling terminal as one coordinated terminal handle.
pub async fn Tty::open() -> Tty {
  let file = @async/fs.open("/dev/tty", mode=ReadWrite)
  Tty::new(file, file)
}
