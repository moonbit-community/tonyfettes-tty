# Isatty OS Error Integration

## Goal

Use `moonbitlang/async/os_error` for `isatty` failures instead of a local
`TtyError`, so terminal handle operations report OS failures consistently.

## Design

- Change `isatty` to raise `@os_error.OSError`.
- Keep valid non-terminal handles returning `false`.
- Return an OS error only for invalid or otherwise failing fd/handle checks.
- Keep the fd-like trait shape so callers can pass values that expose an async
  fd.
- Remove the local `TtyError` error type.

## Public API Changes

- `isatty` changes from raising `TtyError` to raising `@os_error.OSError`.
- The local `TtyError` type is removed from the root interface.
- Add the public `Fd` trait used by generic `isatty`.
- Add an `Fd` impl for `@async/types.Fd`.

## Acceptance

- `isatty` returns `true` for terminal handles.
- `isatty` returns `false` for valid non-terminal handles.
- Invalid fds raise `@os_error.OSError`.
- `.mbti` contains only the intended `isatty` and `Fd` surface changes.

## Validation

- `moon fmt`
- `moon test .`
- `moon check`
- `moon test`
- `moon info`
- review generated `.mbti` diff
- `git diff --check`

## Result

- Changed `isatty` to raise `@os_error.OSError`.
- Removed the root `TtyError` error type.
- Kept non-terminal handles as `false` and invalid fd failures as OS errors.
- Kept the fd-like generic shape by adding a public `Fd` trait and an impl for
  `@async/types.Fd`.
- Updated the invalid fd white-box test to assert the `isatty` OS error
  context.

## Public API Audit

- Root `.mbti` changes `isatty` from `Bool raise TtyError` to
  `Bool raise @os_error.OSError`.
- Root `.mbti` removes `TtyError`.
- Root `.mbti` adds only the intended `Fd` trait and `@async/types.Fd` impl.
- No parser state, terminal handle storage, platform resize behavior, or VT
  output API changed.

## Validation Results

- `moon fmt`
- `moon test .` -> 11 passed
- `moon check`
- `moon test` -> 92 passed
- `moon info`
- generated `.mbti` diff reviewed
- `git diff --check`
