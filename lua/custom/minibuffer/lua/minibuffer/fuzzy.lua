local M = {}

-- Check for Blink (Rust fuzzy) availability
local has_blink, blink_fuzzy = pcall(require, "blink.cmp.fuzzy.rust")

-- Pure Lua fuzzy scorer (fallback)
local function simple_fuzzy_score(str, pattern)
    if pattern == "" then
        return 0
    end
    local total_score = 0
    local run = 0
    local str_idx = 1
    local pat_idx = 1
    local str_len = #str
    local pat_len = #pattern
    local str_lower = str:lower()
    local pat_lower = pattern:lower()

    while pat_idx <= pat_len and str_idx <= str_len do
        local pat_char = pat_lower:sub(pat_idx, pat_idx)
        local found_idx = string.find(str_lower, pat_char, str_idx, true)

        if not found_idx then
            return nil
        end -- Character not found in order

        -- Scoring:
        local distance = found_idx - str_idx
        local score = 100 - distance

        if distance == 0 then
            run = run + 10
            score = score + run
        else
            run = 0
        end

        if found_idx == 1 or str:sub(found_idx - 1, found_idx - 1):match "[^%w]" then
            score = score + 20
        end

        if found_idx > 1 and str:sub(found_idx, found_idx):match "%u" then
            score = score + 20
        end

        total_score = total_score + score
        str_idx = found_idx + 1
        pat_idx = pat_idx + 1
    end

    if pat_idx <= pat_len then
        return nil
    end
    return total_score
end

--- Register items with Blink's Rust engine if available
---@param items table List of strings
function M.register_items(items)
    if not has_blink then
        return false
    end

    local blink_items = {}
    for _, item in ipairs(items) do
        table.insert(blink_items, { label = item, sortText = item })
    end
    blink_fuzzy.set_provider_items("minibuffer", blink_items)
    return true
end

--- Filter items based on query
---@param items_or_provider table|function List of strings or a function(query)
---@param query string The search query
---@param opts table Options { sorter = function, use_blink = boolean }
---@return table matches List of matching strings
function M.filter(items_or_provider, query, opts)
    opts = opts or {}

    if type(items_or_provider) == "function" then
        return items_or_provider(query)
    end

    if query == "" then
        return items_or_provider
    end

    if opts.sorter then
        return opts.sorter(items_or_provider, query)
    end

    -- BLINK (RUST) MATCHING
    if opts.use_blink and has_blink then
        local _, matched_indices, _, _ = blink_fuzzy.fuzzy(query, #query, { "minibuffer" }, {
            max_typos = 0,
            use_frecency = false,
            use_proximity = false,
            nearby_words = {},
            match_suffix = false,
            snippet_score_offset = 0,
            sorts = { "score", "sort_text" },
        })

        local matches = {}
        for _, idx in ipairs(matched_indices) do
            table.insert(matches, items_or_provider[idx + 1])
        end
        return matches
    end

    -- LUA FALLBACK
    local scored = {}
    for _, item in ipairs(items_or_provider) do
        local score = simple_fuzzy_score(item, query)
        if score then
            table.insert(scored, { item = item, score = score })
        end
    end
    table.sort(scored, function(a, b)
        return a.score > b.score
    end)

    local matches = {}
    for _, entry in ipairs(scored) do
        table.insert(matches, entry.item)
    end
    return matches
end

function M.has_blink()
    return has_blink
end

return M
