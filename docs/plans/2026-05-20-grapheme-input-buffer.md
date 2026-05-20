# Grapheme-Aware Input Buffer Demo

## Goal

Make `cmd/input` accept and edit Unicode text in a way that matches user-visible
characters instead of bytes or Unicode scalar values. The demo should handle CJK
text and common emoji sequences without moving line-editing responsibilities
into `tonyfettes/tty/input`.

## Status

Done. Implemented in commit `71ec00f feat(cmd): support grapheme-aware input`.

## Context And Decisions

- `tonyfettes/tty/input` now decodes UTF-8 into text-bearing key events, but it
  intentionally does not define grapheme clusters or terminal cell widths.
- `cmd/input` previously kept an `Array[Byte]` ASCII buffer, which meant valid
  non-ASCII text events were ignored by the demo.
- The demo buffer is now a `String`.
- Appending text uses `KeyEvent::text` when present.
- Backspace removes the last UAX #29 grapheme cluster using `kawaz/grapheme`.
- Prompt status redraw uses `rami3l/unicodewidth` so cursor movement is based on
  terminal display cells, not UTF-16 code units.
- This remains a demo-local line buffer. A reusable line editor, history, or
  completion queue still needs a separate plan before it becomes library API.

## References Or Standards

- UAX #29 Unicode Text Segmentation, via `kawaz/grapheme@0.10.2`.
- UAX #11 East Asian Width/display width, via `rami3l/unicodewidth@0.2.0`.
- Existing UTF-8 input decoding plan:
  `docs/plans/2026-05-20-utf8-input-decoding.md`.

## Target Files

- `moon.mod`
- `cmd/input/moon.pkg`
- `cmd/input/main.mbt`
- `cmd/input/main_wbtest.mbt`
- `docs/architecture.md`
- `docs/plan.md`
- `docs/plans/2026-05-20-grapheme-input-buffer.md`

## Public API Changes

- No public `tonyfettes/tty` or `tonyfettes/tty/input` API changed.
- No new public line-buffer or editor type was introduced.
- Module dependencies now include:
  - `kawaz/grapheme@0.10.2`
  - `rami3l/unicodewidth@0.2.0`

Consumer story:

- Library users still receive decoded input events.
- Demo users can type and delete CJK, combining-mark text, and common emoji
  sequences without byte-level corruption.
- Future library consumers that need reusable line editing should get a planned
  higher-level package rather than depending on `cmd/input`.

## Invariants

- `tonyfettes/tty/input` remains a byte-to-event decoder.
- `KeyEvent::text` remains decoded text, not a grapheme or width guarantee.
- Grapheme segmentation and display-width calculation stay outside the low-level
  input decoder.
- `cmd/input` can use dependencies and demo-local helpers that are not part of
  the public package API.

## Acceptance Criteria

- Typing non-ASCII text appends it to the visible input buffer.
- Backspace removes one user-visible grapheme cluster:
  - CJK characters delete as one unit.
  - combining-mark sequences such as `e + acute` delete as one unit.
  - ZWJ emoji sequences such as family emoji delete as one unit.
- Status text cursor-back logic uses terminal display width.
- Unit tests cover grapheme deletion and display width.

## Validation Commands

```sh
moon test cmd/input
moon test
moon check
moon info
```

Manual validation recommended:

```sh
moon run cmd/input
```

Try CJK text, combining marks, flags, skin tone modifiers, and ZWJ emoji in a
real terminal.

## Validation Results

- `moon test cmd/input` passed: 5 tests.
- `moon test` passed: 58 tests.
- `moon check` passed.
- `moon info` passed.
- Manual terminal validation is still recommended because display-width behavior
  can vary by terminal and font.

## Public API Audit

- No `.mbti` public API changed for the root package, `input`, or `vt`.
- No internal helper from `cmd/input` was exported.
- The added dependencies support demo behavior only.

## Result Notes

- `cmd/input` now uses `String` for the buffer instead of `Array[Byte]`.
- `delete_last_grapheme` is demo-private and implemented through
  `@grapheme.graphemes`.
- `display_width` is demo-private and implemented through
  `@unicodewidth.str_width`.

## Open Questions

- Whether to extract a reusable line-buffer package later.
- Whether bracketed paste should feed text into the same buffer directly or
  produce a distinct paste event first.
- Whether future cursor movement needs grapheme-indexed left/right editing, not
  just append and backspace.
