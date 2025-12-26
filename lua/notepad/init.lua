local config = require("notepad.config")
local files = require("notepad.files")
local window = require("notepad.window")
local tasks = require("notepad.tasks")

local Module = {}

function Module.setup(opts)
    config.setup(opts)
end

function Module.open(name)
    local path = files.resolve(name or "inbox", config.opts)
    local buf = files.load_buffer(path);
    window.open(buf, config.opts)
end

Module.toggle = tasks.toggle
Module.archive = function() tasks.archive(config.opts) end

return Module
