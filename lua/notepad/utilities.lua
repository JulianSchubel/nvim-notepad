--Provides plugin utilities
local Module = {}

--Toggles a checkbox on the current cursor line between checked / unchecked
function Module.toggle()
    --Read the full text of the line under the cursor
    local line = vim.api.nvim_get_current_line()

    --Check for an unchecked task indicator;
    if line:match("%- %[%]") then
        --Replace the unchecked occurence with a checked task indicator
        line = line:gsub("%- %[x%]", "- [x]", 1)
    elseif line:match("%- %[x%]") then
        --Replace the checked occurence with an unchecked indicator
        line = line:gsub("%- %[x%]", "- [ ]", 1)
    else
        --Do nothing on no match; prevent accidental edits
        return
    end

    --Write the modified line back into the buffer
    --This is an undoable operation, integrated into Neovim's undo tree
    vim.api.nvim_set_current_line(line)
end

-- Move completed tasks (- [x]) out of the curernt buffer and appends them to an
-- archive file
function Module.archive(opts)
    --Archiving feature flag; enable archiving to be configured
    if not opts.archive.enabled then return end

    --Get the active buffer handle
    local buf = vim.api.nvim_get_current_buf()
    --Read all lines from the current buffer
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    --Create two tables
    --  - Remaining: stays in the buffer
    --  - Archived: written to the archive file
    local remaining, archived = {}, {}

    --Iterate line-by-line
    for _, line in ipairs(lines) do
        --Determine if the task is completed / checked
        if line:match("%- %[x%]") then
            --Insert into archive table
            table.insert(archived, line)
        else
            --Insert into remaining table
            table.insert(remaining, line)
        end
    end

    --If nothing was completed; do nothing
    --Avoids unnecessary buffer writes or file I/O
    if #archived == 0 then return end

    --Replace the entire buffer content with only the remaining tasks
    --This is a single operation so provides a clean undo step
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, remaining)
    --Append archived tasks to the archive file
    vim.fn.writefile(archived, opts.archive.file, "a")
end

return Module
