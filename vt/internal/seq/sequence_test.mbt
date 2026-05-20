///|
test "csi sequences" {
  @debug.assert_eq(csi1(1, b'A'), b"\x1b[1A")
  @debug.assert_eq(csi1(12, b'B'), b"\x1b[12B")
  @debug.assert_eq(csi2(1, 1, b'H'), b"\x1b[1;1H")
  @debug.assert_eq(csi2(12, 34, b'H'), b"\x1b[12;34H")
}

///|
test "sgr sequences" {
  @debug.assert_eq(sgr1(0), b"\x1b[0m")
  @debug.assert_eq(sgr3(38, 5, 42), b"\x1b[38;5;42m")
  @debug.assert_eq(sgr5(38, 2, 1, 127, 255), b"\x1b[38;2;1;127;255m")
}
