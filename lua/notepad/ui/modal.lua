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

--Attach keymaps to handle input submission and cancellation
local function attach_input_keymaps(modal_id)
    local buffer = Module.state[modal_id].input_buffer
    local close = function () Module.close(modal_id) end

    vim.keymap.set("i", "<CR>", function()
        local line = vim.api.nvim_get_current_line()
        local value = vim.trim(line:gsub("^> ", ""))

        if type(Module.state[modal_id].on_submit) == "function" then
            Module.state[modal_id].on_submit(value)
            close();
        end
    end, { buffer = buffer })

    vim.keymap.set({ "i", "n" }, "<Esc>", close, { buffer = buffer })
end

local function attach_content_keymaps(modal_id)
    local buffer = Module.state[modal_id].content_buffer
    --Set keymaps
    local close = function () Module.close(modal_id) end;
    vim.keymap.set("n", "<Esc>", close, { buffer = buffer, nowait = true });
    --vim.keymap.set("n", "<CR>", close, { buffer = buffer, nowait = true });
    -- vim.keymap.set("n", "q", close, { buffer = buffer, nowait = true });
end

--Compute the window layout configuration
local function compute_layout(modal_id)
    local content_buffer = Module.state[modal_id].content_buffer;
    local columns = vim.o.columns;
    local rows    = vim.o.lines;
    local lines   = Module.state[modal_id].content_lines;
    utilities.display.highlight_line(content_buffer, namespace, 0, 0, "ErrorMsg");

    local V_PADDING = 6;
    local H_PADDING = 6;
    --Compute clamped viewport scaling with Neovim display width. Width is
    --clamped to a minimum of 40 columns and the width of the Neovim display
    --width less horizontal padding.
    local width = math.max(40, math.min(80 - H_PADDING, math.floor(columns * 0.7)))
    --clamped to a minimum of 5 rows and the height of the Neovim display height
    --less vertical padding
    local content_height = #lines + 2
    local input_height = Module.state[modal_id].has_input and 1 or 0
    local height = math.max(5, math.min(rows - V_PADDING, #lines));

    -- Centre the window
    local row = math.floor((rows - height) / 2)
    local col = math.floor((columns - width) / 2)

    return {
        content = {
            relative = "editor",
            style = "minimal",
            border = "rounded",
            width = width,
            height = height,
            row = row,
            col = col,
            title = Module.opts.title,
            title_pos = "center",
        },
        input = Module.state[modal_id].has_input and {
            relative = "win",
            win = Module.state[modal_id].content_window,
            row = content_height,
            col = -1,
            width = width,
            height = 1,
            style = "minimal",
            border = "rounded",
        } or nil,
    }
end

--Handle resize events
function Module.attach_autocommands(modal_id)
    --Add cleanup of the input buffer even on forced window closure
    if Module.state[modal_id].has_input then
        Module.state[modal_id].cleanup_autocmd_id = vim.api.nvim_create_autocmd("WinClosed", {
            --Auto command deletes itself
            once = true,
            callback = function()
                if Module.state[modal_id].input_buffer
                   and vim.api.nvim_buf_is_valid(Module.state[modal_id].input_buffer)
                then
                    vim.api.nvim_buf_delete(Module.state[modal_id].input_buffer, { force = true })
                end
            end,
        })
    end

    Module.state[modal_id].resize_autocmd_id = vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
            --Reduce multiple calls to one call once events stop triggering.
            utilities.debounce(function()
                --Defer until Neovim has finalized grid sizes so we don't get stale values
                --Runs after the current redraw/layout cycle; resize after Neovim is done resizing.
                vim.schedule(function()
                    local content_window = Module.state[modal_id].content_window;
                    --Check if the window is valid; if not, early return.
                    if not vim.api.nvim_win_is_valid(content_window) then
                        return
                    end
                    --Recompute the layout post resizing
                    local layout = compute_layout(modal_id);
                    Module.state[modal_id].layout = layout;

                    --Reset the modal window's properties
                    vim.api.nvim_win_set_config(content_window, layout.content)
                    if Module.state[modal_id].input_window then
                        local input_window = Module.state[modal_id].input_window;
                        vim.api.nvim_win_set_config(
                            input_window,
                            layout.input
                        )
                    end
                end)
            end);
        end,
    });
end

--Helper function to set content buffer options
local function configure_content_buffer(modal_id)
    local buffer = Module.state[modal_id].content_buffer

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
    -- utilities.display.highlight_line(buffer, namespace, 0, 0, "ErrorMsg");

    --Discard buffer when hidden
    vim.bo[buffer].bufhidden = "wipe";

    --Disable everything except dismissal; ensures that the window feels like a modal
    vim.bo[buffer].buftype = "nofile";
    vim.bo[buffer].swapfile = false;
    vim.bo[buffer].readonly = true;
    vim.bo[buffer].modifiable = false;

    -- Ensure Treesitter highlighting works in scratch buffers
    if vim.treesitter and vim.treesitter.start then
        pcall(vim.treesitter.start, buffer, "markdown")
    end
end

--Helper function to set content window options
local function configure_content_window(modal_id)
    local window = Module.state[modal_id].content_window
    local ns_id = Module.state[modal_id].hl_ns
    --Define modal highlights
    vim.api.nvim_set_hl(ns_id, "NormalFloat", { bg = "#1f2430" })
    vim.api.nvim_set_hl(ns_id, "FloatBorder", { bg = "#1f2430", fg = "#6b7089" })
    vim.api.nvim_set_hl(ns_id, "FloatTitle", { bg = "#1f2430", fg = "#6b7089" })
    --Apply modal highlights
    vim.api.nvim_win_set_hl_ns(window, ns_id)
    --Do not highlight the line of text under the cursor
    vim.wo[window].cursorline =false;
    -- Set window transparency
    vim.wo[window].winblend = Module.opts.transparency or 0;
end

--Helper function to set input buffer options
local function configure_input_buffer(modal_id)
    local buffer = Module.state[modal_id].input_buffer
    vim.bo[buffer].buftype = "prompt"
    vim.bo[buffer].swapfile = false
    vim.bo[buffer].modifiable = true
    vim.bo[buffer].bufhidden = "wipe"
    vim.fn.prompt_setprompt(buffer, "> ")
end
--Helper function to set input window options
local function configure_input_window(modal_id)
    local window = Module.state[modal_id].input_window
    local ns_id = Module.state[modal_id].hl_ns
    --Define modal highlights
    vim.api.nvim_set_hl(ns_id, "NormalFloat", { bg = "#1f2430" })
    vim.api.nvim_set_hl(ns_id, "FloatBorder", { bg = "#1f2430", fg = "#6b7089" })
    vim.api.nvim_set_hl(ns_id, "FloatTitle", { bg = "#1f2430", fg = "#6b7089" })
    --Apply modal highlights
    vim.api.nvim_win_set_hl_ns(window, ns_id)
    --Do not highlight the line of text under the cursor
    vim.wo[window].cursorline =false;
    -- Set window transparency
    vim.wo[window].winblend = Module.opts.transparency or 0;
end

--Set default options
local default = {
    exit_prompt = true,
    transparency = 25,
    max_width = 80,
    max_height = 20,
    title = "Message",
    input = {
        enabled = false,
        on_submit = function () end;
    }
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
            "  Press <Esc> to close",
        });
    end

    --Create the content buffer: an unlisted scratch buffer to hold the message content
    math.randomseed(os.time());
    local modal_id = math.random(9999);
    Module.state[modal_id] = {
        hl_ns = vim.api.nvim_create_namespace("notepad.modal." .. modal_id),
        on_submit = Module.opts.input.on_submit,
        has_input =  Module.opts.input.enabled,
    };

    local content_buffer = vim.api.nvim_create_buf(false, true);
    Module.state[modal_id].content_buffer = content_buffer;
    --Initialize a buffer namespaced state table
    --Set the content lines state
    Module.state[modal_id].content_lines = lines
    --Set the buffer content
    vim.api.nvim_buf_set_lines(Module.state[modal_id].content_buffer, 0, -1, false, lines);
    local layout = compute_layout(modal_id);
    Module.state[modal_id].layout = layout;
    --Configure the modals buffer
    configure_content_buffer(modal_id);

    --Create the content window
    --Modal window scales with message length but is clamped between 40 and 80 columns.
    local content_window = vim.api.nvim_open_win(
        content_buffer,
        true,
        layout.content
    );

    --Set the content window state
    Module.state[modal_id].content_window = content_window;
    --Configure the modals window
    configure_content_window(modal_id);
    --Attach a resize handler and record the associated id as state
    --Set keymaps for the buffer (close method)
    attach_content_keymaps(modal_id);

    if Module.opts.input.enabled then
        --Create the input buffer: an unlisted buffer
        local input_buffer = vim.api.nvim_create_buf(false, true)
        Module.state[modal_id].input_buffer = input_buffer;
        configure_input_buffer(modal_id);
        local input_window = vim.api.nvim_open_win(input_buffer, false, layout.input)
        Module.state[modal_id].input_window = input_window;
        configure_input_window(modal_id);
        attach_input_keymaps(modal_id);
        vim.api.nvim_set_current_win(input_window)
        vim.cmd("startinsert")
    end
    Module.attach_autocommands(modal_id);
    return modal_id;
end

--Define a close modal function
function Module.close(modal_id)
    --We have to access namespaced values at module level; values can change
    --across invocations
    local content_window = Module.state[modal_id].content_window;
    local input_window = Module.state[modal_id].input_window;
    -- Close windows
    for _, window in ipairs({ content_window,  input_window}) do
        if window and vim.api.nvim_win_is_valid(window) then
            vim.api.nvim_win_close(window, true)
        end
    end

    --Remove auto commands
    if Module.state[modal_id].resize_autocmd_id then
        vim.api.nvim_del_autocmd(Module.state[modal_id].resize_autocmd_id)
    end
    Module.state[modal_id] = nil;
end

return Module
