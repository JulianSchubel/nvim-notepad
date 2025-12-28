--Toggles a checkbox on the current cursor line between checked / unchecked
local function toggle()
    --Read the full text of the line under the cursor
    local line = vim.api.nvim_get_current_line()

    vim.notify(line, vim.log.levels.WARN)
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

return toggle
