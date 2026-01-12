# nvim-notepad — Stage 1: FSRS Core

The notepad flashcards feature uses a **Lua implementation of the FSRS
(Free Spaced Repetition Scheduler)**.

## Why FSRS?

- See ![ABC-of-FSRS](https://github.com/open-spaced-repetition/fsrs4anki/wiki/ABC-of-FSRS)

## Metadata format

Stored inside Markdown as HTML comments:

```md
<!-- nvim-notepad:fsrs
stability: 4.23
difficulty: 6.87
last_review: 2026-01-05
due: 2026-01-10
-->
