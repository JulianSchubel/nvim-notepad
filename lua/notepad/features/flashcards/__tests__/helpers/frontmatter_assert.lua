local frontmatter = require(
    "notepad.features.flashcards.frontmatter"
)

local M = {}

function M.assert_frontmatter(path, expected)
    local lines = vim.fn.readfile(path)
    local fm = frontmatter.read(lines)

    for k, v in pairs(expected) do
        assert.are.same(v, fm.notepad.flashcard[k])
    end
end

return M
