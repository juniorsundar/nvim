-- Glyph and highlight for LSP CompletionItemKind and SymbolKind names, shared by completion and breadcrumbs.
local M = {}

--- Kind name -> { glyph, group that `MicroKind<Name>` links to }.
---@type table<string, string[]>
M.KINDS = {
    Text = { "󰉿", "@string" },
    Method = { "󰆧", "@function.method" },
    Function = { "󰊕", "@function" },
    Constructor = { "", "@constructor" },
    Field = { "󰜢", "@variable.member" },
    Variable = { "󰀫", "@variable" },
    Class = { "󰠱", "@type" },
    Interface = { "", "@type" },
    Module = { "", "@module" },
    Property = { "󰜢", "@property" },
    Unit = { "󰑭", "@number" },
    Value = { "󰎠", "@number" },
    Enum = { "", "@type" },
    Keyword = { "󰌋", "@keyword" },
    Snippet = { "", "@markup.raw" },
    Color = { "󰏘", "@constant" },
    File = { "󰈙", "Normal" },
    Reference = { "󰈇", "@markup.link" },
    Folder = { "󰉋", "Directory" },
    EnumMember = { "", "@constant" },
    Constant = { "󰏿", "@constant" },
    Struct = { "󰙅", "@type" },
    Event = { "", "@type" },
    Operator = { "󰆕", "@operator" },
    TypeParameter = { "", "@type" },
    Namespace = { "󰦮", "@module" },
    Package = { "", "@module" },
    String = { "", "@string" },
    Number = { "󰎠", "@number" },
    Boolean = { "", "@boolean" },
    Array = { "󰅪", "@type" },
    Object = { "", "@type" },
    Key = { "󰌋", "@property" },
    Null = { "󰟢", "@constant" },
}

--- Create default `MicroKind<Name>` links; safe to call repeatedly (e.g. on ColorScheme).
---@param names? string[] Defaults to every kind.
function M.highlights(names)
    for _, name in ipairs(names or vim.tbl_keys(M.KINDS)) do
        vim.api.nvim_set_hl(0, "MicroKind" .. name, { link = M.KINDS[name][2], default = true })
    end
end

return M
