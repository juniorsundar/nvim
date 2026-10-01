-- Native-only trial profile: nvim --clean -u <this file> some.lua
-- Uses the real after/lsp + after/ftplugin flow, with no cmp/blink and with completion
-- dynamicRegistration left at the native default. The active config is not touched.
local config = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h:h:h:h")
vim.opt.rtp:prepend(vim.fn.fnamemodify(config, ":p") .. "lua/custom/micro.nvim")
vim.opt.rtp:append(config .. "/after")
package.path = config .. "/lua/?.lua;" .. config .. "/lua/?/init.lua;" .. package.path

package.preload["config.lsp.serve_capabilities"] = function()
    return vim.lsp.protocol.make_client_capabilities() -- native only; dynamicRegistration stays true
end

vim.cmd.filetype "plugin indent on"
vim.opt.shortmess:append "I"
require("micro.completion").setup {}
require("micro.completion_keys").setup()
