local M = {}

function M.setup()
    require "micro.statusline"
    require "micro.toggle-lnum"
    require "micro.treesit-navigator"
    require "micro.breadcrumbs"
    require "micro.folds"
    require "micro.hover"
    require "micro.signature"
end

return M
