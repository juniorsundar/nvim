return {
  "hrsh7th/nvim-cmp",
  enabled = false,
  name = "nvim-cmp",
  version = false,
  dependencies = {
    { "iguanacucumber/mag-nvim-lsp", name = "cmp-nvim-lsp", opts = {} },
    { "hrsh7th/cmp-nvim-lsp-signature-help", lazy = true },
    "https://codeberg.org/FelipeLema/cmp-async-path",
  },
  config = function()
    local global_snippets = {
      -- { trigger = "shebang", body = "#!/usr/bin/bash" },
    }

    local snippets_by_filetype = {
      -- lua = {
      --     { trigger = "fun", body = "function ${1:name}(${2:args}) $0 end" },
      --     -- other filetypes
      -- },
      -- norg = {
      --     { trigger = "h1", body = '* ${1:text}' }
      -- }
    }

    local function get_buf_snips()
      local ft = vim.bo.filetype
      local snips = vim.list_slice(global_snippets)

      if ft and snippets_by_filetype[ft] then
        vim.list_extend(snips, snippets_by_filetype[ft])
      end

      return snips
    end

    -- cmp source for snippets to show up in completion menu
    local function register_cmp_source()
      local cmp_source = {}
      local cache = {}
      function cmp_source.complete(_, _, callback)
        local bufnr = vim.api.nvim_get_current_buf()
        if not cache[bufnr] then
          local completion_items = vim.tbl_map(function(s)
            ---@type lsp.CompletionItem
            local item = {
              word = s.trigger,
              label = s.trigger,
              kind = vim.lsp.protocol.CompletionItemKind.Snippet,
              insertText = s.body,
              insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
            }
            return item
          end, get_buf_snips())

          cache[bufnr] = completion_items
        end

        callback(cache[bufnr])
      end

      require("cmp").register_source("snips", cmp_source)
    end
    register_cmp_source()

    local has_words_before = function()
      unpack = unpack or table.unpack
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match "%s" == nil
    end

    local cmp = require "cmp"

    local kind_icons = {
      Text = "",
      Method = "󰆧",
      Function = "󰊕",
      Constructor = "",
      Field = "󰇽",
      Variable = "󰂡",
      Class = "󰠱",
      Interface = "",
      Module = "",
      Property = "󰜢",
      Unit = "",
      Value = "󰎠",
      Enum = "",
      Keyword = "󰌋",
      Snippet = "",
      Color = "󰏘",
      File = "󰈙",
      Reference = "",
      Folder = "󰉋",
      EnumMember = "",
      Constant = "󰏿",
      Struct = "",
      Event = "",
      Operator = "",
      TypeParameter = "󰅲",
    }

    cmp.setup {
      view = {
        entries = "custom", -- can be "custom", "wildmenu" or "native"
      },
      formatting = {
        fields = { "kind", "abbr", "menu" },
        format = function(entry, vim_item)
          vim_item.menu = true and "    @" .. entry.source.name .. "" or ""
          vim_item.kind = " " .. kind_icons[vim_item.kind] .. " "
          return vim_item
        end,
      },
      snippet = {
        completion = {
          completeopt = "menu,menuone",
        },
        expand = function(arg)
          vim.snippet.expand(arg.body)
        end,
      },
      window = {
        documentation = cmp.config.window.bordered {
          winhighlight = "Normal:CmpPmenu,CursorLine:PmenuSel,Search:None,FloatBorder:Normal",
        },
        completion = cmp.config.window.bordered {
          winhighlight = "Normal:CmpPmenu,CursorLine:PmenuSel,Search:None,FloatBorder:Normal",
        },
      },
      mapping = cmp.mapping.preset.insert {
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm { select = true }, -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        ["<Tab>"] = cmp.mapping(function(fallback)
          -- Hint: if the completion menu is visible select next one
          if cmp.visible() then
            cmp.select_next_item()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }), -- i - insert mode; s - select mode
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          else
            fallback()
          end
        end, { "i", "s" }),
      },
      sources = cmp.config.sources {
        { name = "nvim_lsp" },
        { name = "snips" },
        { name = "luasnip" },
        { name = "async_path" },
        { name = "nvim_lsp_signature_help" },
        -- { name = "neorg" },
        -- { name = "orgmode" },
      },
    }
  end,
}
