# Input Event Reader

## Goal

Track the current `input` package work that turns raw host input bytes into a
small public event model and validates common terminal key sequences in
`cmd/input`.

## Status

Active.

The implementation is currently in the worktree and should be committed only
after this plan's acceptance criteria and public API audit are current.

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

## References Or Standards

- ECMA-48 CSI structure: parameters, intermediate bytes, final bytes.
- DEC/VT and xterm keyboard conventions for SS3 `ESC O P` through `ESC O S`
  and tilde-form function keys.
- xterm modifier parameter convention where the encoded modifier value is
  `1 + bitmask`.

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

Fill this in before commit with the exact validation commands and outcomes.

## Open Questions

- Whether future text input should use a single `Text(String)` event or keep
  `KeyEvent::{ code: Text, text: Some(...) }`.
- Whether bracketed paste should be decoded by `input` or handled by a separate
  higher-level input package.
- Whether `cmd/input` should remain ASCII-only for the line buffer until a
  grapheme-aware editing plan exists.
