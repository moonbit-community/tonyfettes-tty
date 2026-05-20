# Task Plans

Use this directory for non-trivial implementation or design tasks. A task plan
is both a pre-implementation checklist and a post-implementation audit trail.

## Filename

Use:

```text
YYYY-MM-DD-<slug>.md
```

Example:

```text
2026-05-20-input-event-reader.md
```

## Required Sections

Each task plan should include:

1. Goal
2. Status
3. Context and decisions
4. References or standards
5. Target files
6. Public API changes
7. Invariants
8. Acceptance criteria
9. Validation commands
10. Public API audit
11. Result notes
12. Open questions

## Public API Audit

When `.mbti` or `pub` surface changes, record:

- which public items were added, removed, or changed
- the external consumer story for each item
- whether the change is breaking
- whether any internal helper leaked into public API
- whether generated `.mbti` was reviewed after `moon info`

## Validation Notes

Record the exact commands that were run. If a command was skipped, failed, or
blocked by an environment issue, record that fact instead of claiming the task is
green.

Terminal behavior often depends on a real tty. For those cases, record the
manual command and what was observed.
