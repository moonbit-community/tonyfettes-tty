# Windows Tty Open

## Goal

Make `Tty::open()` usable on Windows by opening the process console input and
output devices instead of trying the Unix-only `/dev/tty` path.

## Status

Done.

## Context and Decisions

`moon run tests/open` currently fails on Windows with:

```text
OSError("@fs.open(): \"/dev/tty\": The system cannot find the path specified.")
```

The Unix implementation already uses a raw-fd backed controlling terminal
handle. Windows does not have `/dev/tty`; the closest low-level console devices
are `CONIN$` and `CONOUT$`. `Tty` also needs distinct input and output handles on
Windows because input raw-mode operations use the input console handle, while
window-size queries use the output console handle.

Use `moonbitlang/async/fs.open` for the Windows console device paths. The async
file wrapper already exposes the handle through this package's `Fd` trait and
already implements the reader/writer traits needed by `Tty::new`, so no
Windows-specific public or private handle wrapper is needed for this task.

## References or Standards

- Microsoft Console `CONIN$` and `CONOUT$` device names.
- Microsoft `CreateFileW`, `GetConsoleMode`, `SetConsoleMode`, and
  `GetConsoleScreenBufferInfo`.
- Existing `moonbitlang/async/fs.open` Windows implementation through
  `CreateFileW`.

## Target Files

- `tty_unix.mbt`
- `docs/plan.md`
- `docs/plans/2026-05-26-windows-tty-open.md`

## Public API Changes

None. `Tty::open()` keeps the existing public signature.

`pkg.generated.mbti` remains unchanged in this task.

## Invariants

- `Tty` remains opaque and non-generic.
- `Tty::open()` owns the files it opens and `Tty::close()` closes them.
- `Tty::open()` raises `@os_error.OSError` when no controlling console is
  available.
- Raw mode remains input-side state.
- Window-size queries continue to use the output-side handle.

## Acceptance Criteria

- On Windows, `Tty::open()` no longer calls `@async/fs.open("/dev/tty")`.
- On Windows, `Tty::open()` opens `CONIN$` for input and `CONOUT$` for output
  through `@async/fs.open`.
- Existing Unix behavior is unchanged.
- There is no public API diff.

## Validation Commands

- `moon fmt` - passed.
- `moon check` - passed with pre-existing Windows warnings for the Unix-only
  `raw_fd` import and Unix-only pty test helpers.
- `moon test .` - passed, 13 tests.
- `moon test` - passed, 103 tests.
- `moon info` - passed with the same Windows warnings as `moon check`.
- `moon run tests/open` - passed; reported `open: ok`, `rows: 30`,
  `cols: 120`.

## Public API Audit

No source public API changed. `moon info` on Windows temporarily rendered the
existing `Fd::fd` return type as `@async/types.Fd` instead of the checked-in
Unix-normalized `Int`; that generated alias churn was reviewed and not retained.
No `.mbti` diff remains in the worktree.

## Result Notes

Implemented the Windows `Tty::open()` path with `@async/fs.open("CONIN$",
mode=ReadWrite)` for input and `@async/fs.open("CONOUT$", mode=ReadWrite)` for
output. If output open fails after input open succeeds, the input file is closed
before the error is re-raised.

The first implementation sketch used custom private Windows wrappers and FFI,
but review showed `moonbitlang/async/fs` already provides the needed Windows
`CreateFileW` behavior and `File` already implements this package's terminal
handle traits. The final implementation reuses that existing code.

## Open Questions

- This task does not enable or restore Windows output virtual-terminal
  processing. That should remain a separate design task if needed.
