///|
test "isatty" {
  debug_inspect(
    @tty.isatty(@async/stdio.stdin.fd()),
    content=(
      #|false
    ),
  )
}
