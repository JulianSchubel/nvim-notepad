local utilities = require("notepad.utilities")

--Provides a Modal window feature
local Module = {
    opts = {}
}

--Create a namespace for buffer highlighting
local namespace = vim.api.nvim_create_namespace("Nvim-notepad.modal")

--Normalizes a multiline string into a table of lines
local function normalize(msg)
    if type(msg) == "string" then
        return vim.split(msg, "\n", { plain = true })
    end
    return msg
end

local default = {
    exit_prompt = true,
    transparency = 25,
    max_width = 80,
    max_height = 20,
    title = "Message",
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
    content = utilities.text.wrap_lines(content, Module.opts.max_width - PADDING);

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
    local width = utilities.display.compute_display_width(lines, 40, 80);
    local height = utilities.misc.clamp(#lines, 5, 20);


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
    utilities.display.highlight_line(buf, namespace, 0, 0, "ErrorMsg");

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
            utilities.display.highlight_line(buf, namespace, height - 1, 0, "Comment")
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

            width = utilities.viewport_adaptive_width(lines, {
                min = 40,
                max = vim.o.columns - 6,
                padding = PADDING,
            })
            height = utilities.viewport_adaptive_height(lines, {
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
