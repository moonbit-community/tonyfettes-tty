#if defined(_WIN32)
#include <moonbit.h>
#include <windows.h>

MOONBIT_FFI_EXPORT
int32_t
moonbit_tty_isatty(HANDLE fd) {
  DWORD mode;
  if (GetConsoleMode(fd, &mode)) {
    return 1;
  }
  DWORD console_error = GetLastError();
  DWORD file_type = GetFileType(fd);
  if (file_type != FILE_TYPE_UNKNOWN || GetLastError() == NO_ERROR) {
    return 0;
  }
  SetLastError(console_error);
  return -1;
}
#endif
