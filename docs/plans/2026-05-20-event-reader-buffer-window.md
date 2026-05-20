# Event Reader Buffer Window

## Goal

Refactor `tonyfettes/tty/input` so `EventReader` keeps one dynamic ordered byte
window for both current-event bytes and already-read future bytes. This removes
the separate per-parser `@buffer.Buffer` accumulators while preserving the raw
input byte order and existing event behavior.

## Status

Done. The internal API shape was discussed before implementation.

## Agreed Internal API

`EventReader` uses these package-private fields:

- `reader : &@io.Reader`
- `data : FixedArray[Byte]`
- `head : Int`
- `read : Int`
- `tail : Int`

Meanings:

- `head` is the current event start.
- `read` is the next byte to parse.
- `tail` is the end of buffered data.
- `data.length()` is the current buffer capacity.
- `data[head:read]` is the current event view.
- `data[read:tail]` is buffered data not yet consumed by the current event.

Package-private operations:

- `read_byte(timeout?) -> Byte?`
- `unread_byte() -> Unit`
- `view() -> ArrayView[Byte]`
- `ensure_capacity(extra : Int) -> Unit`
- `commit() -> Unit`

Do not add more internal buffer helpers without discussing them first.

## Invariants

- `0 <= head <= read <= tail <= data.length()`.
- `read_byte` writes at `tail` when `read == tail`, growing `data` first when
  needed, then advances `tail` and `read`.
- `unread_byte` takes no byte argument and only rewinds the latest
  `read_byte` advancement by decrementing `read`.
- `view` does not allocate.
- `commit` discards bytes before `read`, compacts `data[read:tail]` to the
  front of the existing buffer, and resets `head` and `read` to `0`.
- The fixed array buffer grows dynamically; the previous fixed unread queue
  limit is removed.
- `@buffer.Buffer` is removed from `input/decoder.mbt`.

## Acceptance Criteria

- Existing input events and unknown byte preservation behavior stay unchanged.
- ESC, CSI, SS3, and UTF-8 parsing all use `EventReader::view`.
- Non-continuation bytes after a UTF-8 lead are handled with `unread_byte()`.
- No parser helper, buffer field, or transition helper appears in
  `input/pkg.generated.mbti`.

## Validation Commands

```sh
moon fmt
moon check
moon test input
moon info
```

No manual terminal validation is required for this internal refactor.

## Validation Results

- `moon fmt` passed.
- `moon check` passed.
- `moon test input` passed: 17 tests passed.
- `moon info` passed.

## Public API Audit

- `input/pkg.generated.mbti` did not expose `EventReader` fields or internal
  buffer operations.
- `read_byte`, `unread_byte`, `view`, `ensure_capacity`, and `commit` remain
  package-private.
- The public `EventReader`, `Event`, `KeyEvent`, and `KeyCode` API shape did
  not change.
