local Module = {
    display = require("notepad.utilities.display"),
    text = require("notepad.utilities.text"),
    debounce = require("notepad.utilities.debounce"),
    misc = {
        clamp = require("notepad.utilities.clamp"),
        debug = require("notepad.utilities.debug"),
    },
    string = {
        trim = require("notepad.utilities.trim"),
    },
    fs = require("notepad.utilities.files"),
    hash = require("notepad.utilities.hash"),
}

return Module
