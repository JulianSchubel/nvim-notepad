local utilities = require("notepad.utilities")

--Provides a Modal window feature
local Module = {
    opts = {},
    --Store references to some key information; mainly required for resizing
    state = {
        lines = nil,

    }
}

--Create a namespace for buffer highlighting
local namespace = vim.api.nvim_create_namespace("Nvim-notepad.modal");

--Normalizes a multiline string into a table of lines
local function normalize(msg)
    if type(msg) == "string" then
        return vim.split(msg, "\n", { plain = true })
    end
    return msg
end


local function set_keymaps(buf)
    --Set keymaps
    local close = function () Module.close(buf) end;
    vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true });
    vim.keymap.set("n", "<CR>", close, { buffer = buf, nowait = true });
    vim.keymap.set("n", "q", close, { buffer = buf, nowait = true });
end

--Compute the window layout configuration
local function compute_layout(buf, padding)
    local columns = vim.o.columns;
    local rows    = vim.o.lines;
    local lines   = Module.state[buf].lines;
    utilities.display.highlight_line(buf, namespace, 0, 0, "ErrorMsg");

    local V_PADDING = 6;
    local H_PADDING = 6;
    --Compute clamped viewport scaling with Neovim display width. Width is
    --clamped to a minimum of 40 columns and the width of the Neovim display
    --width less horizontal padding.
    local width = math.max(40, math.min(80 - H_PADDING, math.floor(columns * 0.7)))
    --clamped to a minimum of 5 rows and the height of the Neovim display height
    --less vertical padding
    local height = math.max(5, math.min(rows - V_PADDING, #lines + 4));

    -- Centre the window
    local row = math.floor((rows - height) / 2)
    local col = math.floor((columns - width) / 2)

    return {
        relative = "editor",
        style = "minimal",
        border = "rounded",
        width = width,
        height = height,
        row = row,
        col = col,
        title = Module.opts.title,
        title_pos = "center",
    }
end

function Module.attach_resize_handler(win)
    return vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
            --Reduce multiple calls to one call once events stop triggering.
            utilities.debounce(function()
                --Defer until Neovim has finalized grid sizes so we don't get stale values
                --Runs after the current redraw/layout cycle; resize after Neovim is done resizing.
                vim.schedule(function()
                    local window = win
                    --Check if the window is valid; if note early return.
                    if not vim.api.nvim_win_is_valid(window) then
                        return
                    end
                    --Recompute the layout post resizing
                    local cfg = compute_layout()
                    --Reset the modal window's properties
                    vim.api.nvim_win_set_config(window, cfg)
                end)
            end);
        end,
    });
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

--Set default options
local default = {
    exit_prompt = true,
    transparency = 25,
    max_width = 80,
    max_height = 20,
    title = "Message",
}

function Module.show(message, opts)
    --Merge user-provided opts with defaults
    Module.opts = vim.tbl_deep_extend("force", default, opts or {});

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

    --Create an unlisted scratch buffer to hold the message content
    local buf = vim.api.nvim_create_buf(false, true);
    --Initialize a buffer namespaced state table
    Module.state[buf] = {}
    --Set the content lines state
    Module.state[buf].lines = lines
    --Set the buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines);
    --Configure the modals buffer
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
    --Modal window scales with message length but is clamped between 40 and 80 columns.
    local window_id = vim.api.nvim_open_win(buf, true, compute_layout(buf))
    --Set the window_id state
    Module.state[buf].window_id = window_id
    --Configure the modals window
    configure_modal_window(window_id);
    --Attach a resize handler and record the associated id as state
    Module.state[buf].resize_autocmd_id = Module.attach_resize_handler(window_id);
    --Set keymaps for the buffer (close method)
    set_keymaps(buf);
    return window_id, buf;
end

--Define a close modal function
function Module.close(buf)
    --We have to access namespaced values as module level values can change
    --across invocations
    local win = Module.state[buf].window_id;
    local resize_autocmd = Module.state[buf].resize_autocmd_id;
    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
    if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end

    if resize_autocmd then
        vim.api.nvim_del_autocmd(resize_autocmd)
        Module.state[buf].resize_autocmd_id = nil
        Module.state[buf].window_id = nil
        Module.state[buf] = nil
    end
end

return Module
