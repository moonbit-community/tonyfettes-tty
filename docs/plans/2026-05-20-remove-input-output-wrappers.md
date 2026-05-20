# Remove Input Output Wrappers

## Goal

Remove root `Input`/`Output` wrapper types and stdio convenience values now that
`Tty` is constructed from terminal `Reader`/`Writer` traits.

## Status

Done.

## Context And Decisions

- `Tty` no longer stores root `Input` or `Output`.
- `Tty::new` accepts concrete terminal handles through root `Reader` and
  `Writer` traits.
- Root `Input`/`Output` now duplicate `moonbitlang/async` file and stdio APIs
  without adding terminal semantics.
- Callers that need terminal operations should use `Tty`.
- Callers that need raw file or stdio I/O should use `moonbitlang/async/fs` or
  `moonbitlang/async/stdio` directly.

## Target Files

- `tty.mbt`
- `tty_unix.mbt`
- `tty_wbtest.mbt`
- `tty_test.mbt`
- `examples/raw/main.mbt`
- `examples/cursor/main.mbt`
- `examples/color/main.mbt`
- `examples/input/main.mbt`
- `examples/pager/main.mbt`
- package `moon.pkg` files as needed
- `pkg.generated.mbti`
- `docs/architecture.md`
- `docs/plan.md`
- `docs/plans/2026-05-20-remove-input-output-wrappers.md`

## Public API Changes

Remove root values:

- `stdin`
- `stdout`
- `stderr`

Remove root types:

- `Input`
- `Output`

Keep:

- `Tty`
- `Tty::stdio`
- `Tty::open`
- `Tty::new`
- `Reader` and `Writer` traits

Breaking change:

- Callers using root `stdin`, `stdout`, `stderr`, `Input`, or `Output` must
  migrate to `Tty` for terminal operations or `moonbitlang/async` for raw I/O.

## Invariants

- `Tty` remains the root terminal capability API.
- `Tty` remains opaque and non-generic.
- `vt` remains byte-only.
- Examples should not use removed root stdio wrappers.

## Acceptance Criteria

- Root `.mbti` no longer exposes `stdin`, `stdout`, `stderr`, `Input`, or
  `Output`.
- Examples compile without `@tty.stdin`, `@tty.stdout`, `@tty.stderr`,
  `@tty.Input`, or `@tty.Output`.
- Root tests cover `Tty::new` with concrete async file handles.

## Validation Commands

```sh
moon fmt
moon test .
moon check examples/raw
moon check examples/cursor
moon check examples/color
moon check examples/input
moon check examples/pager
moon test
moon check
moon info
git diff --check
```

## Validation Results

- `moon fmt`
- `moon test .`
- `moon check examples/raw`
- `moon check examples/cursor`
- `moon check examples/color`
- `moon check examples/input`
- `moon check examples/pager`
- `moon test`
- `moon check`
- `moon info`
- `git diff --check`

## Public API Audit

- Removed root `stdin`, `stdout`, and `stderr`.
- Removed root `Input` and `Output` plus their file/stdout constructors and
  read/write methods.
- Kept opaque `Tty`, `Tty::stdio`, `Tty::open`, generic `Tty::new`, and root
  `Reader`/`Writer` traits.
- `pkg.generated.mbti` now exposes terminal capabilities through `Tty` and
  terminal handle traits only; raw file and stdio I/O should use
  `moonbitlang/async/fs` or `moonbitlang/async/stdio` directly.
