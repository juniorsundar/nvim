local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend("force", capabilities, require("blink.cmp").get_lsp_capabilities(capabilities))
-- capabilities = require('cmp_nvim_lsp').default_capabilities()

capabilities.workspace = {
  didChangeWatchedFiles = {
    dynamicRegistration = true,
  },
}
capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true,
}

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("FoldConfig", { clear = true }),
  callback = function(event)
    vim.o.foldmethod = "expr"
    vim.o.foldcolumn = "1" -- '0' is not bad
    vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true
    vim.o.foldexpr = "nvim_treesitter#foldexpr()"

    local function fold_virt_text(result, s, lnum, coloff)
      if not coloff then
        coloff = 0
      end
      local text = ""
      local hl
      for i = 1, #s do
        local char = s:sub(i, i)
        local hls = vim.treesitter.get_captures_at_pos(0, lnum, coloff + i - 1)
        local _hl = hls[#hls]
        if _hl then
          local new_hl = "@" .. _hl.capture
          if new_hl ~= hl then
            table.insert(result, { text, hl })
            text = ""
            hl = nil
          end
          text = text .. char
          hl = new_hl
        else
          text = text .. char
        end
      end
      table.insert(result, { text, hl })
    end

    function _G.custom_foldtext()
      local start = vim.fn.getline(vim.v.foldstart):gsub("\t", string.rep(" ", vim.o.tabstop))
      local end_str = vim.fn.getline(vim.v.foldend)
      local end_ = vim.trim(end_str)
      local result = {}
      fold_virt_text(result, start, vim.v.foldstart - 1)
      table.insert(result, { " ... ", "Delimiter" })
      fold_virt_text(result, end_, vim.v.foldend - 1, #(end_str:match "^(%s+)" or ""))
      return result
    end

    vim.opt.foldtext = "v:lua.custom_foldtext()"
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(event)
    vim.bo[event.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.server_capabilities.documentHighlightProvider then
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = event.buf,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = event.buf,
        callback = vim.lsp.buf.clear_references,
      })
    end
    if client and client.name == "basedpyright" then
      client.server_capabilities.semanticTokensProvider = nil
    end
    local _, _ = pcall(function()
      vim.keymap.del("n", "K", { buffer = event.buf })
    end)
  end,
})

local momentary_virtual_lines_active = false
vim.keymap.set("n", "<C-w>d", function()
  vim.diagnostic.config { virtual_lines = { current_line = true } }
  momentary_virtual_lines_active = true
end, { desc = "Show momentary diagnostic virtual lines (current line)", remap = true })

local augroup = vim.api.nvim_create_augroup("MomentaryVirtualLines", { clear = true })

vim.api.nvim_create_autocmd("CursorMoved", {
  group = augroup,
  pattern = "*", -- Apply in all buffers
  callback = function()
    if momentary_virtual_lines_active then
      local current_config = vim.diagnostic.config().virtual_lines
      if type(current_config) == "table" and current_config.current_line == true then
        vim.diagnostic.config { virtual_lines = false }
      end
      momentary_virtual_lines_active = false
    end
  end,
})

---- LSP SETUP ----

local mason_bin = vim.fn.stdpath "data" .. "/mason/bin"
vim.env.PATH = mason_bin .. ":" .. vim.env.PATH

vim.diagnostic.config {
  virtual_lines = false,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅙",
      [vim.diagnostic.severity.INFO] = "󰋼",
      [vim.diagnostic.severity.HINT] = "󰌵",
      [vim.diagnostic.severity.WARN] = "",
    },
    linehl = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "",
      [vim.diagnostic.severity.WARN] = "",
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
      [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
      [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
      [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
    },
  },
  underline = true,
  update_in_insert = false,
  virtual_text = false,
}

vim.lsp.config["lua-language-server"] = {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        library = {
          "${3rd}/luv/library",
          unpack(vim.api.nvim_get_runtime_file("", true)),
        },
      },
      completion = {
        callSnippet = "Replace",
      },
      hint = {
        enable = true,
      },
    },
  },
}

vim.lsp.config["basedpyright"] = {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  capabilities = capabilities,
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = "standard",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
      },
    },
  },
  single_file_support = true,
  root_markers = {
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    "pyrightconfig.json",
    ".git",
  },
}

vim.lsp.config["ruff"] = {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_markers = { ".git", "pyproject.toml", "ruff.toml", ".ruff.toml" },
  single_file_support = true,
  capabilities = capabilities,
}
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_attach_disable_ruff_hover", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client == nil then
      return
    end
    if client.name == "ruff" then
      -- Disable hover in favor of Pyright
      client.server_capabilities.hoverProvider = false
    end
  end,
  desc = "LSP: Disable hover capability from Ruff",
})

vim.lsp.config["clangd"] = {
  cmd = { "clangd" },
  filetypes = { "cpp", "hpp", "h", "c", "cuda" },
  root_markers = { "compile_commands.json", ".clangd", ".git" },
  capabilities = capabilities,
}

vim.lsp.config["zls"] = {
  cmd = { "zls" },
  filetypes = { "zig" },
  root_markers = { "zls.json", "build.zig", ".git" },
  single_file_support = true,
  capabilities = capabilities,
}

vim.lsp.config["gopls"] = {
  cmd = { "gopls" },
  filetypes = { "go", "gomod" },
  root_markers = { "go.mod", "go.sum", ".git" },
  single_file_support = true,
  capabilities = capabilities,
  settings = {
    gopls = {
      ["ui.inlayhint.hints"] = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
}

vim.lsp.config["rust-analyzer"] = {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", ".git" },
  -- single_file_support = true,
  capabilities = capabilities,
}

vim.lsp.config["marksman"] = {
  cmd = { "marksman" },
  filetypes = { "markdown" },
  root_markers = { ".marksman.toml", ".git" },
  single_file_support = true,
  capabilities = capabilities,
}

vim.lsp.config["docker-compose"] = {
  cmd = { "docker-compose-langserver", "--stdio" },
  filetypes = { "yaml" },
  root_markers = { "docker-compose.yaml", "docker-compose.yml", "compose.yaml", "compose.yml" },
  capabilities = capabilities,
}

vim.lsp.config["dockerfile"] = {
  cmd = { "docker-langserver", "--stdio" },
  filetypes = { "dockerfile" },
  root_markers = { "Dockerfile" },
  capabilities = capabilities,
}

vim.lsp.config["serve-d"] = {
  cmd = { "serve-d" },
  filetypes = { "d" },
  root_markers = { "dub.json", "dub.sdl", ".git" },
  single_file_support = true,
  capabilities = capabilities,
}
