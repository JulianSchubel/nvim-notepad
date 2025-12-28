--Provides a Modal window feature
local Module = {
    opts = {}
}

--Create a namespace for buffer highlighting
local namespace = vim.api.nvim_create_namespace("Nvim-notepad.modal")

--Clamps a value in the interval `[min, max]`
local function clamp(value, min, max)
    return math.min(max, math.max(min, value));
end

--Calculates a safe range for extmark highlighting of a single line.
--We compute the real line length and clamp the column to the line length,
--ensureing we always specify a valid range.
--This avoids errors in cases where the highlight start or end col > line length
local function highlight_line(buffer, namespace, start_row, start_column, highlight_group)
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

--Returns the max number of display cells required to render lines clamped the
--interval [min_width, max_width]. Helps to calculate Unicode string display widths.
local function compute_dispaly_width(lines, min_width, max_width)
    local w = 0
    for _, line in ipairs(lines) do
        w = math.max(w, vim.fn.strdisplaywidth(line))
    end
    return math.min(max_width, math.max(min_width, w))
end

--Normalizes a multiline string into a table of lines
local function normalize(msg)
    if type(msg) == "string" then
        return vim.split(msg, "\n", { plain = true })
    end
    return msg
end

--Wrap a line if line length > max_width
--Works with Unicode.
local function wrap_line(line, max_width)
    local out = {}
    local rest = line

    --strdisplaywidth() matches what neovim actually renders
    while vim.fn.strdisplaywidth(rest) > max_width do
        local width = 0
        local idx = 0

        while true do
            --Splits by characters, not bytes; does not break graphemes.
            local ch = vim.fn.strcharpart(rest, idx, 1)
            if ch == "" then break end
            local w = vim.fn.strdisplaywidth(ch)
            if width + w > max_width then break end
            width = width + w
            idx = idx + 1
        end

        table.insert(out, vim.fn.strcharpart(rest, 0, idx))
        rest = vim.fn.strcharpart(rest, idx)
    end

    table.insert(out, rest)
    return out
end

--Helper function to wrap all lines in a table where length > max_width
local function wrap_lines(lines, max_width)
    local out = {}
    for _, line in ipairs(lines) do
        vim.list_extend(out, wrap_line(line, max_width))
    end
    return out
end

--Truncate line where length > max_width
--Works with Unicode
local function truncate_line(line, max_width)
    local width = 0
    local idx = 0

    while true do
        local char = vim.fn.strcharpart(line, idx, 1)
        if char == "" then break end
        local w = vim.fn.strdisplaywidth(char)
        if width + w > max_width then break end
        width = width + w
        idx = idx + 1
    end

    return vim.fn.strcharpart(line, 0, idx)
end

--Helper function to truncate all lines in a table where length > max_width
local function truncate_lines(lines, max_width)
    local out = {}
    for _, line in ipairs(lines) do
        table.insert(out, truncate_line(line, max_width))
    end
    return out
end


local default = {
    exit_prompt = true,
    transparency = 25,
    max_width = 80,
    max_height = 20,
    title = "Message",
}

--Calculate viewport adaptive width
local function viewport_adaptive_width(lines, opts)
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
local function viewport_adaptive_height(lines, opts)
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

local function compute_display_width(lines, min_width, max_width)
    local w = 0
    for _, line in ipairs(lines) do
        w = math.max(w, vim.fn.strdisplaywidth(line))
    end
    return math.min(max_width, math.max(min_width, w))
end


--Helper function to set modal buffer options
local function configure_modal_buffer(buf)
    --Discard buffer when hidden
    vim.bo[buf].bufhidden = "wipe";
    --Disable everything except dismissal; ensures that the window feels like a modal
    vim.bo[buf].buftype = "nofile";
    vim.bo[buf].swapfile = false;
    vim.bo[buf].readonly = true;
    vim.bo[buf].modifiable = false;
    -- Ensure Treesitter highlighting works in scratch buffers
    if vim.treesitter and vim.treesitter.start then
        pcall(vim.treesitter.start, buf, "markdown")
    end
end

--Helper function to set modal window options
local function configure_modal_window(win)
    -- Set modal colours
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1f2430" })
    vim.api.nvim_set_hl(0, "FloatBorder", { bg = "#1f2430", fg = "#6b7089" })
    vim.api.nvim_set_hl(0, "FloatTitle", { bg = "#1f2430", fg = "#6b7089" })
    --Do not highlight the line of text under the cursor
    vim.wo[win].cursorline =false;
    -- Set window transparency
    vim.wo[win].winblend = Module.opts.transparency or 0;
end

function Module.show(message, opts)
    --Merge user-provided opts with defaults
    Module.opts = vim.tbl_deep_extend("force", default, opts or {});

    local title = Module.opts.title or "Message";
    local PADDING = 4

    --The number of padding spaces added to each line (2 before, 2 after)
    --Acquire normalized message content
    local content = normalize(message);
    --Wrap lines that exceed configured length
    content = wrap_lines(content, Module.opts.max_width - PADDING);

    --Add padding for alignment to message content
    local lines = vim.list_extend(
        { "" },
        vim.tbl_map(function(line) return "  " .. line .. "  " end, content)
    );

    --Add dismissal prompt to message content
    if Module.opts.exit_prompt then
        vim.list_extend(lines, {
            "",
            "  Press <Enter>, <Esc>, or <q> to close",
        });
    end

    --Modal window width scales with message length but is clamped between 40 and 80 columns.
    local width = compute_display_width(lines, 40, 80);
    local height = clamp(#lines, 5, 20);


    --Create an unlisted scratch buffer to hold the message content
    local buf = vim.api.nvim_create_buf(false, true);
    --Set the buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines);
    configure_modal_buffer(buf);

    --Severity highlighting:
    --  ∙ Built-in Neovim in highlight groups:
    --    / -------------------------------------------/
    --    | Group         | Purpose                    |
    --    | ------------- | -------------------------- |
    --    | `ErrorMsg`    | Errors                     |
    --    | `WarningMsg`  | Warnings                   |
    --    | `MoreMsg`     | Success / info             |
    --    | `Question`    | Prompts                    |
    --    | `Title`       | Headers                    |
    --    | `Visual`      | Selection                  |
    --    | `NormalFloat` | Floating window background |
    --    | `FloatBorder` | Floating window borders    |
    --    / ------------------------------------------ /
    highlight_line(buf, namespace, 0, 0, "ErrorMsg");

    --Create the window
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
        title = title,
        title_pos = "center",
    });
    configure_modal_window(win);

    local needs_scroll = #lines > height;
    if needs_scroll then
        vim.wo[win].scrolloff = 0
        vim.wo[win].wrap = false
        vim.wo[win].linebreak = false
        vim.keymap.set("n", "<C-j>", function()
            vim.cmd("normal! <C-e>")
        end, { buffer = buf })

        vim.keymap.set("n", "<C-k>", function()
            vim.cmd("normal! <C-y>")
        end, { buffer = buf })
        if needs_scroll then
            highlight_line(buf, namespace, height - 1, 0, "Comment")
        end
    end

    --Define a close modal function
    local function close()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end

    --Set keymaps
    vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true });
    vim.keymap.set("n", "<CR>", close, { buffer = buf, nowait = true });
    vim.keymap.set("n", "q", close, { buffer = buf, nowait = true });

    --Recompute width and height on resize
    vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
            if not vim.api.nvim_win_is_valid(win) then return end

            width = viewport_adaptive_width(lines, {
                min = 40,
                max = vim.o.columns - 6,
                padding = PADDING,
            })
            height = viewport_adaptive_height(lines, {
                min = 5,
                max = vim.o.lines - 4,
                padding = PADDING,
            })

            needs_scroll = #lines > height

            vim.api.nvim_win_set_config(win, { height = height, width = width })
        end,
    })

    return win, buf;
end

return Module
