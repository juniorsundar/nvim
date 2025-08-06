return {
  "obsidian-nvim/obsidian.nvim",
  enabled = true,
  keys = {
    { "<localleader>O", group = "Obsidian" },
    { "<localleader>OD", group = "Dailies" },
    { "<localleader>Oo", "<cmd>Obsidian quick_switch<cr>", desc = "Quick Switch" },
    { "<localleader>Of", "<cmd>Obsidian search<cr>", desc = "Search" },
    { "<localleader>Ot", "<cmd>Obsidian tags<cr>", desc = "Tags" },
    { "<localleader>Ol", "<cmd>Obsidian links<cr>", desc = "Links" },
    { "<localleader>Ot", "<cmd>Obsidian tags<cr>", desc = "Tags" },
    { "<localleader>Ob", "<cmd>Obsidian backlinks<cr>", desc = "Backlinks" },
    { "<localleader>ODt", "<cmd>Obsidian today<cr>", desc = "Today" },
    { "<localleader>ODT", "<cmd>Obsidian tomorrow<cr>", desc = "Tomorrow" },
    { "<localleader>ODy", "<cmd>Obsidian yesterday<cr>", desc = "Yesterday" },
  },
  version = "*",
  config = function()
    require("obsidian").setup {
      legacy_commands = false,
      workspaces = {
        {
          name = "vault",
          path = "~/Dropbox/obsidian/vault",
          overrides = {
            notes_subdir = "pages",
            daily_notes = {
              folder = "journals",
              template = "journal_template.md",
            },
          },
        },
        {
          name = "gow",
          path = "~/Dropbox/obsidian/gow",
        },
      },
      completion = {
        nvim_cmp = false,
        blink = true,
        min_chars = 1,
      },
      picker = {
        name = "snacks.pick",
        note_mappings = {
          new = "<C-x>",
          insert_link = "<C-l>",
        },
        tag_mappings = {
          tag_note = "<C-x>",
          insert_tag = "<C-l>",
        },
      },
      templates = {
        folder = "templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
        substitutions = {},
      },
      ui = {
        enable = false,
      },
      disable_frontmatter = true,
      attachments = {
        img_folder = "assets",
        img_name_func = function()
          return string.format("%s-", os.time())
        end,

        img_text_func = function(client, path)
          path = client:vault_relative_path(path) or path
          return string.format("![%s](%s)", path.name, path)
        end,
      },
    }
    require("which-key").add {
    }
  end,
}
