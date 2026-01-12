--Called nside review modal submit handler, after FSRS update.
local M = {}

local DATA_FILE = vim.fn.stdpath("data") .. "/notepad/reviews.json"

local function read()
    if vim.fn.filereadable(DATA_FILE) == 0 then
        return {}
    end
    local content = table.concat(vim.fn.readfile(DATA_FILE), "\n")
    return vim.json.decode(content) or {}
end

local function write(data)
    vim.fn.mkdir(vim.fn.fnamemodify(DATA_FILE, ":h"), "p")
    vim.fn.writefile({ vim.json.encode(data) }, DATA_FILE)
end

function M.log(card_id, rating, ts)
    local data = read()
    table.insert(data, {
        card = card_id,
        rating = rating,
        ts = ts or os.time(),
    })
    write(data)
end

function M.all()
    return read()
end

return M
