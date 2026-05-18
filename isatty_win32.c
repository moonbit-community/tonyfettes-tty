#if defined(_WIN32)
#include <io.h>
#include <moonbit.h>

MOONBIT_FFI_EXPORT
int32_t
moonbit_tty_isatty(HANDLE fd) {
  DWORD mode;
  return GetConsoleMode(fd, &mode) ? 1 : 0;
}
#endif
