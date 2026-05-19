local M = {}

M.user_opts = nil

--- HlTerm warning
---@param msg string Text to be displayed as a warning
M.warn = function(msg) vim.notify(msg, vim.log.levels.WARN, { title = "hlterm" }) end

--- Setup
---@param opts? HlTermUserOpts
M.setup = function(opts)
    if opts then M.user_opts = opts end
end

--- Return user options
---@return HlTermUserOpts
M.get_user_opts = function() return M.user_opts end

return M
