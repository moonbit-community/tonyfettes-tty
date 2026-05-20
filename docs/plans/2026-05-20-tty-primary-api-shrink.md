# Tty Primary API Shrink

## Goal

Shrink root `Input` and `Output` so terminal capabilities are exposed through
root `Tty`, while `Input` and `Output` remain low-level handle/read/write
wrappers.

## Status

Done.

## Context And Decisions

- `Tty` is now the root user-facing terminal handle because it coordinates one
  input stream and one output stream.
- Terminal capabilities such as raw mode, alternate screen, window size,
  cursor visibility, and style commands should live on `Tty`.
- `Input` should remain useful as a low-level readable handle: open, fd, close,
  read, read_some, and read_byte.
- `Output` should remain useful as a low-level writable handle: open, fd,
  close, write, and write_string.
- `Input` raw-mode state methods and `Output` terminal command methods stay
  package-private so `Tty` can delegate without keeping them in the root public
  surface.
- `@tty/vt` remains the pure byte-sequence layer for callers who want to write
  raw VT bytes themselves.

## Target Files

- `state.mbt`
- `size.mbt`
- `style.mbt`
- `tty_handle.mbt`
- `pkg.generated.mbti`
- `tty_test.mbt`
- `tty_wbtest.mbt`
- `examples/raw/main.mbt`
- `examples/cursor/main.mbt`
- `examples/color/main.mbt`
- `examples/pager/main.mbt`
- `docs/architecture.md`
- `docs/plan.md`
- `docs/plans/2026-05-20-tty-primary-api-shrink.md`

## Public API Changes

Add root `Tty` methods:

- `Tty::get_state`
- `Tty::set_state`
- `Tty::enter_raw_mode`
- `Tty::leave_raw_mode`
- `Tty::enter_alt_screen`
- `Tty::leave_alt_screen`
- `Tty::with_alt_screen`

Remove root `Input` public methods:

- `Input::get_state`
- `Input::set_state`
- `Input::enter_raw_mode`
- `Input::leave_raw_mode`
- `Input::with_raw_mode`

Remove root `Output` public methods:

- `Output::window_size`
- `Output::enter_alt_screen`
- `Output::leave_alt_screen`
- `Output::with_alt_screen`
- `Output::hide_cursor`
- `Output::show_cursor`
- `Output::set_foreground`
- `Output::set_background`
- `Output::reset_foreground`
- `Output::reset_background`
- `Output::reset_style`

Keep root `Input` public low-level handle/reader methods:

- `Input::open`
- `Input::fd`
- `Input::close`
- `Input::read`
- `Input::read_some`
- `Input::read_byte`

Keep root `Output` public low-level handle/writer methods:

- `Output::open`
- `Output::fd`
- `Output::close`
- `Output::write`
- `Output::write_string`

Breaking change:

- Callers using terminal capabilities on `Input`/`Output` must migrate to
  `Tty`.

## Invariants

- `Tty` remains a coordination handle, not a screen renderer or TUI framework.
- Raw-mode state remains implemented against the underlying input handle.
- Window-size queries remain implemented against the underlying output handle.
- `Input` and `Output` should not expose terminal capabilities in root
  `pkg.generated.mbti`.
- Examples should use `Tty` for terminal capabilities.

## Acceptance Criteria

- Root `.mbti` exposes terminal capabilities on `Tty`, not `Input`/`Output`.
- Examples compile after moving raw mode, color/style commands, alt screen, and
  window-size queries to `Tty`.
- Existing low-level read/write handle tests still pass.

## Validation Commands

```sh
moon fmt
moon test .
moon check examples/raw
moon check examples/cursor
moon check examples/color
moon check examples/pager
moon test
moon check
moon info
git diff --check
```

## Validation Results

- `moon fmt` passed.
- `moon test .` passed: 15 tests.
- `moon check examples/raw` passed.
- `moon check examples/cursor` passed.
- `moon check examples/color` passed.
- `moon check examples/pager` passed.
- `moon test` passed: 93 tests.
- `moon check` passed.
- `moon info` passed and regenerated public interfaces.
- `git diff --check` passed.

## Public API Audit

- Root `Input` public API now contains only low-level handle/read operations:
  `open`, `fd`, `close`, `read`, `read_some`, and `read_byte`.
- Root `Output` public API now contains only low-level handle/write operations:
  `open`, `fd`, `close`, `write`, and `write_string`.
- Raw-mode state operations moved to public `Tty` methods:
  `get_state`, `set_state`, `enter_raw_mode`, `leave_raw_mode`, and
  `with_raw_mode`.
- Alternate-screen operations moved to public `Tty` methods:
  `enter_alt_screen`, `leave_alt_screen`, and `with_alt_screen`.
- Window-size, cursor visibility, style commands, cursor-position query,
  decoded event reading, and terminal writes are all available from `Tty`.
- `State::make_raw` remains public because callers using `Tty::get_state` and
  `Tty::set_state` may need to derive raw state explicitly.
