vim.pack.add { "https://github.com/NeogitOrg/neogit" }

local neogit_loaded = false

local function load_neogit(args)
    if neogit_loaded then
        return
    end
    neogit_loaded = true

    require("neogit").setup {
        disable_hint = true,
        signs = {
            hunk = { "", "" },
            item = { "", "" },
            section = { "", "" },
        },
        graph_style = "unicode",
        integrations = {
            telescope = nil,
            diffview = nil,
            fzf_lua = nil,
            mini_pick = nil,
            snacks = nil,
        },
    }

    -- Route neogit's async fuzzy finder through refer.nvim.
    local neogit_async = require "neogit.lib.async"
    local FuzzyFinderBuffer = require "neogit.buffers.fuzzy_finder"
    local refer = require "refer"

    local function refocus_status_buffer()
        local status = require "neogit.buffers.status"
        if status.instance() then
            status.instance():focus()
            status.instance():dispatch_refresh(nil, "finder.refocus")
        end
    end

    FuzzyFinderBuffer.open_async = neogit_async.wrap(function(self, opts, cb)
        opts = opts or {}

        -- neogit resumes its async task on this callback; it must fire exactly once.
        local delivered = false
        local function deliver(value)
            if delivered then
                return
            end
            delivered = true
            cb(value)
            if opts.refocus_status ~= false then
                vim.schedule(refocus_status_buffer)
            end
        end

        local picker_opts = {
            _refer_internal = true,
            multiselect = opts.allow_multi == true,
            prompt = (opts.prompt_prefix or "select") .. ": ",
            on_close = function()
                vim.schedule(function()
                    deliver(nil)
                end)
            end,
            keymaps = opts.allow_multi == true and {} or {
                ["<CR>"] = { action = "select_entry", desc = "Choose entry" },
            },
        }

        local height = opts.layout_config and opts.layout_config.height
        if height then
            picker_opts.max_height = height > 1 and math.floor(height) or math.floor(vim.o.lines * height)
        end

        refer.pick(self.list, function(selection)
            deliver(selection)
        end, picker_opts)
    end, 3)

    -- Replace the lazy shims with the real commands.
    vim.keymap.set("n", "<leader>Gg", "<cmd>Neogit<cr>", { desc = "Neogit" })
    vim.keymap.set("n", "<leader>G.", "<cmd>Neogit cwd=%:p:h<cr>", { desc = "Open to CWD" })

    -- Run the command that triggered the load.
    if args then
        vim.cmd(args)
    end
end

vim.keymap.set("n", "<leader>Gg", function()
    load_neogit "Neogit"
end, { desc = "Neogit" })
vim.keymap.set("n", "<leader>G.", function()
    load_neogit "Neogit cwd=%:p:h"
end, { desc = "Open to CWD" })

vim.keymap.set("n", "<leader>GDd", function()
    local abs_file = vim.fn.expand "%:p"
    if abs_file == "" then
        print "No file found"
        return
    end

    local file_dir = vim.fn.fnamemodify(abs_file, ":h")
    local git_root =
        vim.fn.system("git -C " .. vim.fn.shellescape(file_dir) .. " rev-parse --show-toplevel"):gsub("%s+", "")

    if vim.v.shell_error ~= 0 then
        print "Not in a git repository."
        return
    end

    local base_git = "git -C " .. vim.fn.shellescape(git_root) .. " "

    local git_rel_file_raw = vim.fn.system(base_git .. "ls-files --full-name " .. vim.fn.shellescape(abs_file))
    local git_rel_file = string.match(git_rel_file_raw, "[^\r\n]+")

    if not git_rel_file then
        print "File is not tracked by Git."
        return
    end

    local is_unmerged = vim.fn.system(base_git .. "ls-files -u " .. vim.fn.shellescape(git_rel_file))
    if vim.v.shell_error ~= 0 or is_unmerged == "" then
        print "This file does not have active merge conflicts in the Git index."
        return
    end

    vim.cmd "tab split"
    local center_buf = vim.api.nvim_get_current_buf()

    vim.cmd "leftabove vnew"
    vim.cmd("silent read !" .. base_git .. "show :2:" .. vim.fn.shellescape(git_rel_file))
    vim.cmd "0d_"
    vim.cmd "diffthis"
    vim.cmd "setlocal buftype=nofile readonly nomodifiable"
    vim.cmd("file " .. vim.fn.fnameescape(git_rel_file) .. " (Ours)")
    local ours_buf = vim.api.nvim_get_current_buf()

    vim.cmd "wincmd l"
    vim.cmd "diffthis"

    vim.cmd "rightbelow vnew"
    vim.cmd("silent read !" .. base_git .. "show :3:" .. vim.fn.shellescape(git_rel_file))
    vim.cmd "0d_"
    vim.cmd "diffthis"
    vim.cmd "setlocal buftype=nofile readonly nomodifiable"
    vim.cmd("file " .. vim.fn.fnameescape(git_rel_file) .. " (Theirs)")
    local theirs_buf = vim.api.nvim_get_current_buf()

    vim.cmd "wincmd h"
    local opts = { buffer = center_buf, noremap = true, silent = true }

    vim.keymap.set("n", "<leader>GDCo", ":diffget " .. ours_buf .. "<CR>:diffupdate<CR>", opts)
    vim.keymap.set("n", "<leader>GDCt", ":diffget " .. theirs_buf .. "<CR>:diffupdate<CR>", opts)

    vim.keymap.set("n", "<leader>GDCb", function()
        local start_line = vim.fn.search("^<<<<<<<", "bcW")
        local end_line = vim.fn.search("^>>>>>>>", "W")

        if start_line > 0 and end_line > 0 then
            vim.cmd(end_line .. "d")
            local base_start = vim.fn.search("^|||||||", "bnW", start_line)
            local separator = vim.fn.search("^=======", "bnW", end_line)

            if base_start > 0 and separator > 0 then
                vim.cmd(base_start .. "," .. separator .. "d")
            else
                vim.cmd "?^=======?d"
            end

            vim.cmd(start_line .. "d")
            vim.cmd "diffupdate"
        end
    end, opts)

    vim.keymap.set("n", "<leader>GDq", ":tabclose<CR>", opts)
end, { desc = "Open 3-way Git conflict diff" })
