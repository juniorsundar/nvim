return {
  {
    "nvim-neorg/neorg",
    event = "VeryLazy",
    dependencies = {
      {
        { dir = "~/.config/nvim_plugins/neorg-extras" },
        "juniorsundar/neorg-extras",
      },
    },
    config = function()
      require("neorg").setup {
        load = {
          ["core.defaults"] = {},
          ["core.esupports.indent"] = {},
          ["core.concealer"] = {
            config = {
              icon_preset = "varied",
              icons = {
                list = {
                  icons = { "󰧞", "", "", "", "", "" },
                },
                heading = {
                  icons = { "󰼏", "󰼐", "󰼑", "󰼒", "󰼓", "󰼔" },
                },
              },
            },
          },
          ["core.dirman"] = {
            config = {
              workspaces = {
                default = "~/Dropbox/notes",
                the_good_teacher = "~/Dropbox/tgt",
                god_of_war = "~/Dropbox/gow",
              },
            },
          },
          ["core.export"] = {},
          ["core.journal"] = {
            config = {
              strategy = "flat",
            },
          },
          ["core.highlights"] = {},
          ["core.export.markdown"] = {},
          ["core.completion"] = {
            config = {
              engine = "nvim-cmp",
            },
          },
          ["core.latex.renderer"] = {},
          ["core.integrations.image"] = {},
          ["core.integrations.nvim-cmp"] = {},
          ["core.summary"] = {},
          ["core.qol.toc"] = {},
          ["core.qol.todo_items"] = {},
          ["core.looking-glass"] = {},
          ["core.presenter"] = {
            config = {
              zen_mode = "zen-mode",
            },
          },
          ["core.tangle"] = {
            config = {
              report_on_empty = false,
            },
          },
          ["core.tempus"] = {},
          ["core.ui.calendar"] = {},
          ["external.agenda"] = {},
          ["external.roam"] = {
            config = {
              fuzzy_finder = "Fzf",
              fuzzy_backlinks = false,
              roam_base_directory = "vault",
              node_name_randomiser = true,
            },
          },
          ["external.many-mans"] = {
            config = {
              metadata_fold = true,
              code_fold = false,
            },
          },
        },
      }

      require("neorg.core").modules.get_module("core.dirman").set_workspace "default"

      vim.keymap.set(
        "n",
        "<leader>NT",
        "<cmd>Neorg cycle_task<CR>",
        { noremap = true, silent = true, desc = "Cycle task" }
      )
      vim.keymap.set(
        "n",
        "<leader>N_",
        "<cmd>Neorg update_property_metadata<CR>",
        { noremap = true, silent = true, desc = "Update property metadata" }
      )
      vim.keymap.set(
        "n",
        "<leader>NFB",
        "<cmd>Neorg roam backlinks<cr>",
        { noremap = true, silent = true, desc = "Backlinks" }
      )
      vim.keymap.set(
        "n",
        "<leader>Nw",
        "<cmd>Neorg roam select_workspace<cr>",
        { noremap = true, silent = true, desc = "Workspaces" }
      )
      vim.keymap.set(
        "n",
        "<leader>NFb",
        "<cmd>Neorg roam block<cr>",
        { noremap = true, silent = true, desc = "Block Injector" }
      )
      vim.keymap.set(
        "n",
        "<leader>NFn",
        "<cmd>Neorg roam node<cr>",
        { noremap = true, silent = true, desc = "Node Injector" }
      )
      vim.keymap.set(
        "n",
        "<leader>NAd",
        "<cmd>Neorg agenda day<cr>",
        { noremap = true, silent = true, desc = "Neorg Agenda Day" }
      )
      vim.keymap.set(
        "n",
        "<leader>NAp",
        "<cmd>Neorg agenda page undone pending hold<cr>",
        { noremap = true, silent = true, desc = "Neorg Agenda Page" }
      )
      vim.keymap.set(
        "n",
        "<leader>NAt",
        "<cmd>Neorg agenda tag<cr>",
        { noremap = true, silent = true, desc = "Neorg Agenda Tag" }
      )
      vim.keymap.set(
        "n",
        "<leader>Nt",
        "<cmd>Neorg toc<cr>",
        { noremap = true, silent = true, desc = "Table of Contents" }
      )
      vim.keymap.set("n", "<leader>Ni", "<cmd>Neorg index<cr>", { noremap = true, silent = true, desc = "Index" })
      vim.keymap.set(
        "n",
        "<leader>NJt",
        "<cmd>Neorg journal today<cr>",
        { noremap = true, silent = true, desc = "Today's Journal" }
      )
      vim.keymap.set(
        "n",
        "<leader>NJm",
        "<cmd>Neorg journal tomorrow<cr>",
        { noremap = true, silent = true, desc = "Tomorrow's Journal" }
      )
      vim.keymap.set(
        "n",
        "<leader>NJy",
        "<cmd>Neorg journal yesterday<cr>",
        { noremap = true, silent = true, desc = "Yesterday's Journal" }
      )
      vim.keymap.set(
        "n",
        "<leader>NMi",
        "<cmd>Neorg inject-metadata<cr>",
        { noremap = true, silent = true, desc = "Inject" }
      )
      vim.keymap.set(
        "n",
        "<leader>NMu",
        "<cmd>Neorg update-metadata<cr>",
        { noremap = true, silent = true, desc = "Update" }
      )
    end,
  },
  ---------------------------------------------------------------------------------------
  {
    "https://github.com/leafo/magick",
  },
  {
    "3rd/diagram.nvim",
    ft = { "markdown", "norg" },
    dependencies = {
      {
        "3rd/image.nvim",
        event = "VeryLazy",
        config = function()
          require("image").setup {
            backend = "kitty",
            integrations = {
              markdown = {
                enabled = true,
                clear_in_insert_mode = false,
                download_remote_images = true,
                only_render_image_at_cursor = true,
                filetypes = { "markdown", "vimwiki", "quarto" }, -- markdown extensions (ie. quarto) can go here
              },
              neorg = {
                enabled = true,
                clear_in_insert_mode = false,
                download_remote_images = true,
                only_render_image_at_cursor = true,
                filetypes = { "norg" },
              },
            },
            max_width = nil,
            max_height = nil,
            max_width_window_percentage = 50,
            max_height_window_percentage = 50,
            window_overlap_clear_enabled = false, -- toggles images when windows are overlapped
            window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
            editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
            tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
            hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp" }, -- render image files as images when opened
          }
        end,
      },
    },
    config = function()
      require("diagram").setup { -- you can just pass {}, defaults below
        integrations = {
          require "diagram.integrations.neorg",
        },
        renderer_options = {
          mermaid = {
            background = nil, -- nil | "transparent" | "white" | "#hex"
            theme = nil, -- nil | "default" | "dark" | "forest" | "neutral"
            scale = 1, -- nil | 1 (default) | 2  | 3 | ...
          },
          plantuml = {
            charset = nil,
          },
          d2 = {
            theme_id = nil,
            dark_theme_id = nil,
            scale = nil,
            layout = nil,
            sketch = nil,
          },
        },
      }
    end,
  },
  ---------------------------------------------------------------------------------------
}
