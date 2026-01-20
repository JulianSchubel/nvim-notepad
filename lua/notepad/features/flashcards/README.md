# Flashcards  

The flashcards feature adds staged repition flashcards with obsidian
compatibility in mind. Flashcard content is identitified in markdown files in
the following manner:
1. Inline: 
    ```sh
    Q :: A
    ```
    Single line with the question and answer delimited by ` :: `.  
    (note that the delimiter is inclusive of a leading and trailing `' '` character.)
2. Multiline: 
    ```sh
    Q::... 

    A::...
    ```
    All lines following the character sequence `Q::` are considered the question.  
    All lines following the character sequence `A::` are considered the answer.
3. Obsidian-style Callout: 
    ```sh
    >[!flashcard] 
    Q... 

    A...
    ``` 
    The first and second paragraphs form the question and answer repsectively.

# Troubleshooting  

To confirm that ratings have been applied you can inspect the metadata for all
currently registered flashcards by running the following:
```vim
:lua print(vim.inspect(require("notepad.features.flashcards.metadata")._state.notes))
```
