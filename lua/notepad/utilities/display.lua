local clamp = require("notepad.utilities.clamp")

--Provides display utilities: calculating viewport adaptive layout sizes etc.
local Module = {}

--Calculate viewport adaptive width
function Module.viewport_adaptive_width(lines, opts)
    opts = opts or {}

    local min_w = opts.min or 40
    local max_w = opts.max or (vim.o.columns - 6)
    local padding = opts.padding or 0

    local content_w = 0
    for _, line in ipairs(lines) do
        content_w = math.max(content_w, vim.fn.strdisplaywidth(line))
    end

    -- Account for left/right padding
    local desired = content_w + padding * 2

    -- Clamp to viewport
    return math.min(
        max_w,
        math.max(min_w, desired)
    )
end

--Calculate view port adaptive height
function Module.viewport_adaptive_height(lines, opts)
    opts = opts or {}

    local min_h = opts.min or 5
    local max_h = opts.max or (vim.o.lines - 4)
    local padding = opts.padding or 0

    -- Content height is just number of rendered lines
    local content_h = #lines

    -- Account for vertical padding (top + bottom)
    local desired = content_h + padding * 2

    -- Clamp to viewport
    return math.min(
        max_h,
        math.max(min_h, desired)
    )
end

--Returns the max number of display cells required to render lines clamped the
--interval `[min_width, max_width]`. Helps to calculate Unicode string display widths.
function Module.compute_display_width(lines, min_width, max_width)
    local w = 0
    for _, line in ipairs(lines) do
        w = math.max(w, vim.fn.strdisplaywidth(line))
    end
    return math.min(max_width, math.max(min_width, w))
end

--Returns the number of lines required to render lines clamped the
--interval `[min_height, max_height]`.
function Module.compute_display_height(lines, min_height, max_height)
    return clamp(lines, min_height, max_height)
end

--Calculates a safe range for extmark highlighting of a single line.
--We compute the real line length and clamp the column to the line length,
--ensureing we always specify a valid range.
--This avoids errors in cases where the highlight start or end col > line length
function Module.highlight_line(buffer, namespace, start_row, start_column, highlight_group)
    local text = vim.api.nvim_buf_get_lines(buffer, start_row, start_row + 1, false)[1] or "";

    local length = vim.fn.strlen(text);

    -- Clamp start column into valid range
    local col = math.min(start_column, length);

    vim.api.nvim_buf_set_extmark(
        buffer,
        namespace,
        --Start of highlight row (0 based)
        start_row,
        --Start of highlight column (0 based)
        col,
        {
            --Highlight group to apply
            hl_group = highlight_group,
            --Highlight past the last character to the end of the screen line. Useful for headers or banners.
            hl_eol = true,
            --Highlight end column
            end_col = length,
        }
    );
end

return Module
