-- Move completed tasks (- [x]) out of the curernt buffer and appends them to an
-- archive file
local function archive(opts)
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

return archive
