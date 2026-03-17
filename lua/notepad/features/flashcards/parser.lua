-- Extract flashcard content from files
local utilities = require("notepad.utilities")
local M = {}

-- -------------------------------------
-- Utility: strip leading "> " safely
-- -------------------------------------
local function strip_quote(line)
    return line:gsub("^>%s?", "")
end

-- --------------------------------------------
-- Parse Obsidian flashcard callouts
-- --------------------------------------------
-- @example
--
--      >[!flashcard]
--      What is a computer?
--
--      A programmable device capable of executing logical instructions.
--
local function parse_callouts(lines, source)
    local flashcards = {}
    local i = 1

    while i <= #lines do
        if lines[i]:match("^>%s*%[!flashcard%]") then
            i = i + 1

            local question = nil
            local answer_lines = {}

            while i <= #lines and lines[i]:match("^>") do
                local content = strip_quote(lines[i])

                if content ~= "" then
                    if not question then
                        question = content
                    else
                        table.insert(answer_lines, content)
                    end
                end

                i = i + 1
            end

            table.insert(flashcards, {
                question = question or "",
                answer   = table.concat(answer_lines, "\n"),
                note_id  = source.note_id,
                source   = {
                    path = source.path,
                    line = source.line,
                    type = "callout",
                    hash = source.hash,
                },
            })
        else
            i = i + 1
        end
    end

    return flashcards
end


-- -----------------------------------------------------------
-- Parse Multiline Question (Q::*) and Answer (A::*) Pairs with optional
-- choices (C::*) (choices must be supplied between a question and answer)
-- -----------------------------------------------------------
-- @example 
--
--      Q:: What is Lua?
--      A:: A lightweight embeddable scripting language.
--
--      Q:: What is FSRS? 
--      A:: FSRS is a modern spaced repetition algorithm
--          designed to optimize long-term memory.
--
--      Q:: 2 + 2 is?
--      C:: 1
--      C:: 3
--      A:: 4
--
local function parse_qna_pairs(lines, source)
    assert(type(lines) == "table", "parse_qna_pairs expects lines[]")

    local flashcards = {}
    local question = nil
    local answer = nil
    local choices = {}
    local choice_index = 1;

    for _, line in ipairs(lines) do
        local prefix, content = line:match("^([QCA])::%s*(.+)")

        if prefix == "Q" then
            question = content;
        elseif prefix == "C" then
            table.insert(choices, choice_index, content);
            choice_index = choice_index + 1;
        elseif prefix == "A" then
            answer = content;
            if choice_index > 1 then
                table.insert(choices, choice_index, content);
            end
            table.insert(flashcards, {
                question = question,
                answer   = answer,
                answer_index = choice_index,
                choices  = choices,
                note_id  = source.note_id,
                source   = {
                    path = source.path,
                    line = source.line,
                    type = "qna",
                    hash = source.hash,
                },
            })
            question = nil -- reset after pairing
            if choice_index > 0 then
                answer = nil -- reset after pairing (in the case that there are choices
                choices = {} --reset choices
                choice_index = 0; -- reset choice_index
            end
        end
    end

    return flashcards
end

-- ------------------------------------------------------
-- Inline ` :: ` Delimited Question and Answer Pairs
-- ------------------------------------------------------
-- @example
--
--      What is the capital of France? :: Paris
--
local function parse_inline(lines, source)
    local flashcards = {}
    for _, line in ipairs(lines) do
        if line:find(" :: ") then
            local front, back = line:match("^(.-)::(.-)$")
            if front and back then
                table.insert(flashcards, {
                    question = utilities.string.trim(front),
                    answer   = utilities.string.trim(back),
                    note_id  = source.note_id,
                    source   = {
                        path = source.path,
                        line = source.line,
                        type = "inline",
                        hash = source.hash,
                    },
                })
            end
        end
    end

    return flashcards
end

-- -----------------------------------------------------------
-- Parse Multiple-choice Answer Question (Q::*) and Answer (A::*) Pairs
-- -----------------------------------------------------------
-- @example 
--
--      Q:: What is Lua?
--      A:: A lightweight embeddable scripting language.
--
--      Q:: What is FSRS? 
--      A:: FSRS is a modern spaced repetition algorithm
--          designed to optimize long-term memory.
--

local schema = require("notepad.features.flashcards.schema")

-- ------------------------------------------------------
-- Extracts flashcards questions and ansers from file
-- ------------------------------------------------------
-- @param lines string[] | lines of the file content
-- @param source table | file metadata (path, hash, etc.)
function M.parse_file(lines, source)
    if type(lines) == "string" then
        lines = vim.split(lines, "\n", { plain = true })
    end

    local flashcards = {}
    -- each parser should match only their case and nothing else.
    vim.list_extend(flashcards, parse_qna_pairs(lines, source))
    vim.list_extend(flashcards, parse_callouts(lines, source))
    vim.list_extend(flashcards, parse_inline(lines, source))

    return {
        cards = flashcards,
        raw = lines,
        path = source.path,
    }
end

-- ------------------------------------------
-- Extracts flashcard content from files
-- ------------------------------------------
-- @param input table | string - An array of file content
function M.parse_files(input)
    local files = input

    -- Allow single-string input (tests)
    if type(input) == "string" then
        files = {
            {
                path = "",
                content = input,
            },
        }
    end

    assert(type(files) == "table", "parse_files expects string or files[]")

    local cards = {}

    for _, file in ipairs(files) do
        local lines = file.lines or file.content
        if type(lines) == "string" then
            lines = vim.split(lines, "\n", { plain = true })
        end
        assert(type(lines) == "table", "file must have .lines[] or .content property")
        assert(file.hash, "file.hash missing before parsing")


        local result = M.parse_file(lines, {
            path = file.path or "",
            line = 1,
            hash = file.hash,
            note_id = file.note and file.note.id or nil,
        })

        vim.list_extend(cards, result.cards)
    end

    return cards
end


-- ----------------------------------------------------
-- Compatibility wrapper for tests and simple usage
-- ----------------------------------------------------
function M.parse(input)
    return M.parse_file(input, {
        path = "",
        line = 1,
    })
end

return M;

