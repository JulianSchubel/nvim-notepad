# Stage 3 — Flashcard Review Modal

This stage introduces the interactive review flow.

## Components

- `review.lua` — FSRS review state machine
- `review_modal.lua` — UI wrapper using notepad modal
- No Telescope dependency yet

## Interaction

| Key | Action |
|----|-------|
| 1 | Again |
| 2 | Hard |
| 3 | Good |
| 4 | Easy |
| Esc | Cancel |

## Guarantees

- FSRS-compliant updates
- Markdown-first content
- Obsidian-safe persistence
- No UI state leakage

## Next Stage

Stage 4 adds a Telescope picker for **Due Today** cards.

