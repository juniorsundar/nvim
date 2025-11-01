return {
	"ibhagwan/fzf-lua",
	enabled = false,
	cmd = "FzfLua",
	keys = {
		{ "<leader>b", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
		{ "<leader>Ff", "<cmd>FzfLua files<cr>", desc = "Files" },
		{ "<leader>Ft", "<cmd>FzfLua live_grep<CR>", desc = "Text" },
		{ "<leader>Fc", "<cmd>FzfLua colorschemes<cr>", desc = "Colorscheme" },
		{ "<leader>Fh", "<cmd>FzfLua helptags<cr>", desc = "Find Help" },
		{ "<leader>Fk", "<cmd>FzfLua keymaps<cr>", desc = "Keymaps" },
		{ "<leader>Fr", "<cmd>FzfLua oldfiles<cr>", desc = "Open Recent File" },
		{ "<leader>FM", "<cmd>FzfLua manpages<cr>", desc = "Man Pages" },
		{ "<leader>FR", "<cmd>FzfLua registers<cr>", desc = "Registers" },
		{ "<leader>FC", "<cmd>FzfLua commands<cr>", desc = "Commands" },
		{ "<leader>Fl", "<cmd>FzfLua grep_curbuf<cr>", desc = "Line" },
		{ "<leader>Go", "<cmd>FzfLua git_status <cr>", desc = "Open changed file" },
		{ "<leader>Gb", "<cmd>FzfLua git_branches <cr>", desc = "Checkout branch" },
		{ "<leader>Lr", "<cmd>FzfLua lsp_references<cr>", desc = "References" },
		{ "<leader>Lt", "<cmd>FzfLua lsp_typedefs<cr>", desc = "Type Definition" },
		{ "<leader>LDd", "<cmd>FzfLua lsp_document_diagnostics<cr>", desc = "Document Diagnostics" },
		{ "<leader>LDs", "<cmd>FzfLua lsp_document_symbols <cr>", desc = "Document Symbols" },
		{ "<leader>LWd", "<cmd>FzfLua lsp_workspace_diagnostics<cr>", desc = "Workspace Diagnostics" },
		{ "<leader>LWs", "<cmd>FzfLua lsp_workspace_symbols <cr>", desc = "Workspace Symbols" },
	},
	config = function()
		local actions = require("fzf-lua.actions")
		require("fzf-lua").setup({
			winopts = {
				split = "belowright new",
				preview = {
					horizontal = "right:50%",
					delay = 50,
				},
			},
		})

		-- FZF INSTALLATION & UPDATE COMMANDS
		local data_path = vim.fn.stdpath("data")
		local fzf_path = data_path .. "/fzf"
		local bin_path = fzf_path .. "/bin"
		vim.env.PATH = bin_path .. ":" .. vim.env.PATH

		local function run_install_script(on_success_msg)
			local install_cmd = string.format("sh -c 'cd %s && ./install --bin'", vim.fn.shellescape(fzf_path))
			vim.notify("Running fzf install script...", vim.log.levels.INFO)
			vim.fn.jobstart(install_cmd, {
				on_exit = function(_, exit_code)
					if exit_code == 0 then
						vim.env.PATH = bin_path .. ":" .. vim.env.PATH
						vim.notify(on_success_msg, vim.log.levels.INFO)
					else
						vim.notify("fzf installation script failed. Exit code: " .. exit_code, vim.log.levels.ERROR)
					end
				end,
			})
		end

		local function fzf_install()
			if vim.fn.executable("fzf") == 1 then
				vim.notify("fzf is already installed and in your PATH.", vim.log.levels.INFO)
				return
			end

			if vim.fn.isdirectory(fzf_path) == 1 then
				vim.notify("fzf repository found locally. Running installer...", vim.log.levels.INFO)
				run_install_script("fzf installed successfully. Added to PATH for this session.")
			else
				vim.notify("Cloning fzf...", vim.log.levels.INFO)
				local clone_cmd = string.format(
					"git clone --depth 1 https://github.com/junegunn/fzf.git %s",
					vim.fn.shellescape(fzf_path)
				)
				vim.fn.jobstart(clone_cmd, {
					on_exit = function(_, exit_code)
						if exit_code == 0 then
							vim.notify("fzf cloned successfully.", vim.log.levels.INFO)
							run_install_script("fzf installed successfully. Added to PATH for this session.")
						else
							vim.notify("Failed to clone fzf repository. Exit code: " .. exit_code, vim.log.levels.ERROR)
						end
					end,
				})
			end
		end

		local function fzf_update()
			if vim.fn.isdirectory(fzf_path) ~= 1 then
				vim.notify("fzf not found locally. Run :FzfLuaInstall first.", vim.log.levels.WARN)
				return
			end

			vim.notify("Updating fzf by running 'git pull'...", vim.log.levels.INFO)
			local pull_cmd = string.format("sh -c 'cd %s && git pull'", vim.fn.shellescape(fzf_path))
			vim.fn.jobstart(pull_cmd, {
				on_exit = function(_, exit_code)
					if exit_code == 0 then
						vim.notify("fzf repository updated successfully.", vim.log.levels.INFO)
						run_install_script("fzf re-installed successfully.")
					else
						vim.notify(
							"Failed to update fzf repository with 'git pull'. Exit code: " .. exit_code,
							vim.log.levels.ERROR
						)
					end
				end,
			})
		end

		local function fzf_version()
			local ok, handle = pcall(io.popen, "fzf --version 2>&1")
			if not ok or not handle then
				vim.notify("Failed to execute fzf", vim.log.levels.ERROR)
				return
			end
			local version = handle:read("*a")
			handle:close()
			if version == "" then
				vim.notify("Failed to get fzf version", vim.log.levels.ERROR)
			else
				version = version:gsub("\n$", "")
				vim.notify("fzf version: " .. version, vim.log.levels.WARN)
			end
		end

		vim.api.nvim_create_user_command("Fzf", function(opts)
			if opts.args == "install" then
				fzf_install()
			elseif opts.args == "update" then
				fzf_update()
			elseif opts.args == "version" then
				fzf_version()
			else
				vim.notify("Unknown command!", vim.log.levels.ERROR)
			end
		end, {
			nargs = 1,
			complete = function(arg_lead, cmd_line, cursor_pos)
				local subcommands = { "install", "update" }

				local existing = vim.fn.getcompletion(arg_lead, "cmdline")

				for _, subcmd in ipairs(subcommands) do
					if vim.startswith(subcmd, arg_lead) then
						table.insert(existing, subcmd)
					end
				end

				return existing
			end,
			desc = "Fzf installation commands.",
		})
	end,
}
