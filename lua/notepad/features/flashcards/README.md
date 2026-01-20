# Flashcards  

The flashcards feature adds staged repition flashcards with obsidian
compatibility in mind. Flashcard content is identitified in markdown files in
the following manner:
1. Inline: `Q :: A`. Single line with the questino and answer delimited by ` :: ` (note
   the leading and trailling whitespace).
2. Multiline: `Q::* ... A::*`. All lines following the character sequence `Q::` are considered
   the question, and all lines following the character sequence `A::` are
   considered the answer.
3. Obsidian-style Callout: `>[!flashcard] Q... A...` The first and second paragraphs form the question and
   answer repsectively.

# Troubleshooting  

To confirm that ratings have been implied you can inspect the metadata for all
currently registered flashcards by running the following:
```vim
:lua print(vim.inspect(require("notepad.features.flashcards.metadata")._state.notes))
```
