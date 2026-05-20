# Input Event Reader

## Goal

Track the current `input` package work that turns raw host input bytes into a
small public event model and validates common terminal key sequences in
`cmd/input`.

## Status

Active.

The common-key implementation has landed. This plan remains active for manual
terminal validation and follow-up policy decisions such as UTF-8 text and
bracketed paste.

## Context And Decisions

- `EventReader` is the public decoder boundary.
- `EventReader` reads from an `@io.Reader`, keeps its own pending bytes, and
  applies the ESC timeout needed to distinguish a standalone Escape key from the
  start of an escape sequence.
- `EventReader::read_byte` stays internal. Callers should read events, not
  manually drive the decoder byte by byte.
- Unsupported recognized-length sequences become `Unknown(Bytes)`.
- A timeout while reading an ESC tail can produce an Escape key or `Unknown`
  depending on the bytes already observed.
- `cmd/input` is the manual validation surface for interactive terminal input.
- Legacy printable ASCII does not infer Shift usage from characters. For
  example, byte `A` becomes `code=Char('A')`, `modifiers=none`, `text="A"`;
  `ESC A` becomes `code=Char('A')`, `modifiers=Alt`, `text=None`.
- Shift is reported only when the terminal explicitly encodes it, such as CSI
  modifier parameters or future enhanced keyboard protocols.
- `ESC [` is ambiguous: it can be Alt+`[` or the beginning of a CSI sequence.
  If no CSI body arrives before the ESC timeout, decode it as Alt+`[`. If any
  CSI body bytes have arrived, keep the timeout result as `Unknown`.

## References Or Standards

- ECMA-48 CSI structure: parameters, intermediate bytes, final bytes.
- DEC/VT and xterm keyboard conventions for SS3 `ESC O P` through `ESC O S`
  and tilde-form function keys.
- xterm modifier parameter convention where the encoded modifier value is
  `1 + bitmask`.
- Crossterm treats `CSI Ps [; modifier] ~` as `parse_csi_special_key_code`,
  with the first parameter selecting Home, Insert, Delete, PageUp, function
  keys, and related special keys.
- Ultraviolet parses CSI into parameters, intermediates, and final byte; it
  handles `~` as a numbered key family and applies xterm-style modifiers from
  the second parameter.

## Target Files

- `input/event.mbt`
- `input/decoder.mbt`
- `input/decoder_test.mbt`
- `input/pkg.generated.mbti`
- `cmd/input/main.mbt`
- `cmd/input/moon.pkg`

## Public API Changes

- `KeyCode::F(Int)` is replaced by explicit `F1` through `F12` variants.

Consumer story:

- Callers usually pattern-match on known function keys, not arbitrary function
  key numbers.
- Explicit variants avoid accepting impossible values such as `F(99)`.
- The public enum communicates the decoder's current supported range.

Breaking change:

- Existing callers matching `F(n)` must update to explicit variants.

## Invariants

- `EventReader` remains the only public reader-style decoder type.
- Internal parser helpers and pending-byte storage do not appear in `.mbti`.
- Unknown sequences preserve their original bytes.
- `cmd/input` can display decoded events but does not define the library API.
- The decoder does not become a Unicode-aware text editor or line buffer.

## Acceptance Criteria

- SS3 cursor sequences decode where supported.
- SS3 `ESC O P`, `ESC O Q`, `ESC O R`, and `ESC O S` decode as `F1` through
  `F4`.
- CSI tilde forms decode common Home, End, Insert, Delete, PageUp, PageDown,
  and function-key sequences.
- xterm-style modifier parameters decode Shift, Alt, Ctrl, and Meta into
  `KeyModifiers`.
- Legacy printable ASCII preserves the received character and does not infer
  Shift from uppercase letters or punctuation.
- Alt+`[` decodes after ESC timeout as `Char('[')` plus `Alt`, while longer
  incomplete CSI sequences remain `Unknown`.
- `cmd/input` prints explicit F-key names and combined modifiers.
- Unsupported sequences still produce `Unknown(Bytes)`.

## Validation Commands

Planned validation:

```sh
moon fmt
moon check
moon test input
moon check cmd/input
moon info
```

Manual validation:

```sh
moon run cmd/input
```

Press F1 through F4 and cursor keys in the current terminal and compare the
displayed events with the expected key names and modifiers.

## Public API Audit

`.mbti` review is required because `KeyCode` changes public shape.

Expected public API result:

- `EventReader` remains opaque.
- `EventReader::new` and `EventReader::read_event` remain the only public
  methods on `EventReader`.
- `KeyCode` exposes explicit `F1` through `F12` variants.
- No parser helper, buffer type, or byte-level read helper is public.

## Result Notes

Partial validation on 2026-05-20:

- `moon fmt` passed.
- `moon check` passed.
- `moon test input` passed: 13 tests.
- `moon check cmd/input` passed.
- `moon info` passed.

Manual `moon run cmd/input` validation is still pending.

Follow-up audit on 2026-05-20:

- Commit `7c00977 refactor(input): match csi keys with rest patterns` rewrote
  `csi_event` to match CSI framing as `ESC [` + params + final byte.
- `CSI Ps [; modifier] ~` is intentionally handled separately because `~` is a
  final byte for a numbered special-key family; the key code is carried by the
  first parameter.
- The refactor follows the same broad split used by crossterm and ultraviolet:
  direct final-byte keys such as `A/B/C/D/H/F/P/Q/R/S`, and numbered
  tilde-form keys such as Delete, PageUp, and F5-F12.
- The refactor did not change the public input API. `moon info` reported no
  generated interface work.
- Validation for the refactor passed before commit: `moon fmt`, `moon test
  input`, `moon check`, and `moon info`.

## Open Questions

- Whether future text input should use a single `Text(String)` event or keep
  `KeyEvent::{ code: Text, text: Some(...) }`.
- Whether bracketed paste should be decoded by `input` or handled by a separate
  higher-level input package.
- Whether `cmd/input` should remain ASCII-only for the line buffer until a
  grapheme-aware editing plan exists.
