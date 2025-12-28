--Provides a Modal window feature
local Module = {}

--Create a namespace for buffer highlighting
local namespace = vim.api.nvim_create_namespace("Nvim-notepad.modal")

--Calculates a safe range for extmark highlighting of a single line.
--We compute the real line length and clamp the column to the line length,
--ensureing we always specify a valid range.
--This avoids errors in cases where the highlight start or end col > line length
local function safe_highlight(buffer, namespace, start_row, start_column, highlight_group)
    local text = vim.api.nvim_buf_get_lines(buffer, start_row, start_row + 1, false)[1] or "";

    local length = vim.fn.strlen(text)

    -- Clamp start column into valid range
    local col = math.min(start_column, length)

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
    })
end

--Normalizes a multiline string into a table of lines
local function normalize(msg)
    if type(msg) == "string" then
        return vim.split(msg, "\n", { plain = true })
    end
    return msg
end

local default = {
    exit_prompt = true,
}

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
    -- Set floating window background
    vim.api.nvim_set_hl(namespace, "NormalFloat", { bg = "#1f2430" })
    vim.api.nvim_set_hl(namespace, "FloatBorder", { bg = "#1f2430", fg = "#6b7089" })
    --Do not highlight the line of text under the cursor
    vim.wo[win].cursorline =false;
end

function Module.show(message, opts)
    --Merge user-provided opts with defaults
    opts = vim.tbl_deep_extend("force", default, opts);

    --Modal window width scales with message length but is clamped between 40 and 80 columns.
    local width = opts.width or math.min(80, math.max(40, #message + 6));
    --Modal height is constant or equivalent to the number of lines
    local height = opts.height or 5;
    local title = opts.title or "Message";

    --Acquire normalized message content
    local content = normalize(message);

    --Add padding for alignment to message content
    local lines = vim.list_extend(
        { "" },
        vim.tbl_map(function(line) return "  " .. line end, content)
    );

    --Add dismissal prompt to message content
    if opts.exit_prompt then
        vim.list_extend(lines, {
            "",
            "  Press <Enter>, <Esc>, or <q> to close",
        });
    end

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
    safe_highlight(buf, namespace, 0, 0, "ErrorMsg");

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

    return win, buf;
end

return Module
