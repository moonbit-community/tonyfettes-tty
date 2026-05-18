#if defined(__APPLE__) || defined(__linux__) || defined(__unix__)
#include <errno.h>
#include <moonbit.h>
#include <stdint.h>
#include <unistd.h>

MOONBIT_FFI_EXPORT
int32_t
moonbit_tty_isatty(int32_t fd) {
  errno = 0;
  if (isatty(fd)) {
    return 1;
  }
  if (errno == EBADF) {
    return -2;
  }
  return 0;
}
#endif
