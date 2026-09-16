vim.pack.add { "https://github.com/NotAShelf/direnv.nvim" }

local bin = "direnv"

if vim.env.OUTPOST_SESSION == "1" then
    local candidates = {
        vim.fs.joinpath(vim.env.HOME, ".nix-profile/bin/direnv"), -- nix on a foreign distro
        "/run/current-system/sw/bin/direnv", -- NixOS system profile
    }

    for _, candidate in ipairs(candidates) do
        if vim.fn.executable(candidate) == 1 then
            bin = candidate
            break
        end
    end
end

require("direnv").setup { bin = bin }
