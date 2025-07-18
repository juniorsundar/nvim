local function lsp_function(handler)
  local params = vim.lsp.util.make_position_params(0, "utf-32")
  vim.lsp.buf_request(0, "textDocument/" .. handler, params, function(err, result, _, _)
    if err or not result or vim.tbl_isempty(result) then
      return
    end

    if #result > 1 then
      vim.cmd("lua Snacks.picker.lsp_" .. handler .. "s()")
    else
      local win_width = vim.o.columns
      local threshold = 120
      if win_width > threshold then
        vim.cmd("vsplit | lua vim.lsp.buf." .. handler .. "()")
      else
        vim.cmd("split | lua vim.lsp.buf." .. handler .. "()")
      end
    end
  end)
end

require("which-key").add {
  { "<leader>L", group = "LSP" },
  { "<leader>LA", group = "DAP" },
  { "<leader>LD", group = "Document" },
  { "<leader>LW", group = "Workspace" },
  {
    "<leader>LI",
    function()
      vim.cmd [[checkhealth lsp]]
    end,
    desc = "LSP Info",
  },
  {
    "<leader>La",
    function()
      vim.lsp.buf.code_action()
    end,
    desc = "Code Action",
  },
  {
    "<leader>Lf",
    function()
      vim.lsp.buf.format()
    end,
    desc = "Format",
  },
  {
    "<leader>Ll",
    function()
      vim.lsp.codelens.run()
    end,
    desc = "CodeLens Action",
  },
  {
    "<leader>Ln",
    function()
      vim.lsp.buf.rename()
    end,
    desc = "Rename",
  },
  {
    "<leader>Lk",
    function()
      vim.lsp.buf.hover { border = "rounded" }
    end,
    desc = "Hover",
  },
  {
    "<leader>LWa",
    function()
      vim.lsp.buf.add_workspace_folder()
    end,
    desc = "Add Workspace Folder",
  },
  {
    "<leader>LWr",
    function()
      vim.lsp.buf.remove_workspace_folder()
    end,
    desc = "Remove Workspace Folder",
  },
  {
    "<leader>LWl",
    function()
      vim.lsp.buf.list_workspace_folders()
    end,
    desc = "List Workspace Folders",
  },
  {
    "<leader>LWs",
    function()
      Snacks.picker.lsp_workspace_symbols()
    end,
    desc = "Workspace Symbols",
  },
  {
    "<leader>LWd",
    function()
      Snacks.picker.diagnostics()
    end,
    desc = "Workspace Diagnostics",
  },
  {
    "<leader>LDs",
    function()
      Snacks.picker.lsp_symbols()
    end,
    desc = "Document Symbols",
  },
  {
    "<leader>LDd",
    function()
      Snacks.picker.diagnostics_buffer()
    end,
    desc = "Document Diagnostics",
  },
  {
    "<leader>Ld",
    function()
      lsp_function "definition"
    end,
    desc = "Definition",
  },
  {
    "<leader>Lc",
    function()
      lsp_function "declaration"
    end,
    desc = "Declaration",
  },
  {
    "<leader>Li",
    function()
      lsp_function "implementation"
    end,
    desc = "Implementation",
  },
  {
    "<leader>Lr",
    function()
      Snacks.picker.lsp_references()
    end,
    desc = "References",
  },
  {
    "<leader>Lt",
    function()
      Snacks.picker.lsp_type_definitions()
    end,
    desc = "Type Definition",
  },
}
