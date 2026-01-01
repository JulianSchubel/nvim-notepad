-- Remove completed tasks (- [x]) from the curernt buffer
local function remove_completed()
    --Get the active buffer handle
    local buf = vim.api.nvim_get_current_buf()
    --Read all lines from the current buffer
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    --Create two tables
    --  - Remaining: stays in the buffer
    --  - Archived: written to the archive file
    local remaining, archived = {}, {}
    --Iterate line-by-line
    local in_completed_item = false;
    for _, line in ipairs(lines) do
        --Determine if the task is completed / checked
        if line:match("%- %`%[x%]%`") then
            in_completed_item = true;
        end
        if line:match("%- %`%[%s?%]%`") then
            in_completed_item = false;
        end
        if in_completed_item then
            --Insert into archive table
            table.insert(archived, line)
        else
            --Insert into remaining table
            table.insert(remaining, line)
        end
    end

    --If nothing was completed; do nothing
    --Avoids unnecessary buffer writes
    if #archived == 0 then return end

    --Replace the entire buffer content with only the remaining tasks
    --This is a single operation so provides a clean undo step
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, remaining)
end

return remove_completed
