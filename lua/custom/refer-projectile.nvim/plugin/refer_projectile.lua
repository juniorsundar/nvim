if vim.g.loaded_refer_projectile then
    return
end
vim.g.loaded_refer_projectile = true

local rp = require "refer_projectile"
local refer = require "refer"

refer.add_command({ "Projectile", "Switch" }, function(_opts)
    rp.pick_project()
end)

refer.add_command({ "Projectile", "Open" }, function(_opts)
    rp.open_project()
end)

refer.add_command({ "Projectile", "Export" }, function(_opts)
    rp.export_scripts()
end)
