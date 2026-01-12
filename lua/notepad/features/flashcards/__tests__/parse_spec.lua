local parser = require("notepad.features.flashcards.parser")

describe("Markdown flashcard parser", function()
    it("parses inline cards", function()
        local result = parser.parse([[
What is 2+2? :: 4
]])

        assert.equals(1, #result.cards)
        assert.equals("What is 2+2?", result.cards[1].question)
        assert.equals("4", result.cards[1].answer)
    end)

    it("parses callout flashcards", function()
        local cards = parser.parse_files({
            {
                path = "test.md",
                lines = {
                    "> [!flashcard]",
                    "> What is TCP?",
                    "> Transmission Control Protocol",
                },
            },
        })

        assert.equals(1, #cards)
        assert.equals("What is TCP?", cards[1].question)
        assert.equals("Transmission Control Protocol", cards[1].answer)
    end)

    it("ignores non-flashcard callouts", function()
        local result = parser.parse([[
> [!note]
> Just a note
]])

        assert.equals(0, #result.cards)
    end)
end)
