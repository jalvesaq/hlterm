local M = {}

local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")

--- Get language of current Quart block of code
--- @return string
M.get_language = function()
    local chunkline = vim.fn.search("^[ \t]*```[ ]*{", "bncW")
    local docline = vim.fn.search("^[ \t]*```$", "bncW")
    if chunkline <= docline then return "none" end
    local cline = vim.fn.getline(chunkline)
    cline = cline:gsub(".*{", "")
    local lng = cline:gsub("%W.*", "")
    local scrpt = plugin_root .. "/ftplugin/" .. lng .. "_hlterm.vim"
    if vim.fn.filereadable(scrpt) == 1 then
        vim.cmd.source(scrpt)
        return lng
    else
        require("hlterm").warn('hlterm does not support file of type "' .. lng .. '"')
        return "none"
    end
end

return M
