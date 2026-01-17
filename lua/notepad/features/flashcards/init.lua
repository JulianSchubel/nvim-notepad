--[[
    It is recommended to add the following CSS styling to Obsidian 
    to make flashcard callouts visually distinct n Obsidian:
        .callout[data-callout="flashcard"] {
          --callout-color: 100, 140, 255;
          --callout-icon: lucide-brain;
        }
]]

-- io.lua -> discovers files, computes hashes
-- parser.lua -> extracts semantic flashcards from text
-- metadata.lua -> attaches FSRS + stats by stable ID
-- query.lua -> determines which cards matter now.
