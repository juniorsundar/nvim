M = {
  capabilities = vim.lsp.protocol.make_client_capabilities(),
}

---@alias blink_loaded boolean
---@alias blink blink.cmp.API
local blink_loaded, blink = pcall(require, "blink.cmp")
if blink_loaded then
  M.capabilities = vim.tbl_deep_extend("force", M.capabilities, blink.get_lsp_capabilities(M.capabilities))
end

M.capabilities.workspace = {
  didChangeWatchedFiles = {
    dynamicRegistration = true,
  },
}
M.capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true,
}

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("FoldConfig", { clear = true }),
  callback = function(_)
    vim.o.foldmethod = "expr"
    vim.o.foldcolumn = "0" -- '0' is not bad
    vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true
    -- vim.o.foldexpr = "nvim_treesitter#foldexpr()"

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

return M
