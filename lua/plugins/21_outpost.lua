require("outpost").setup {
    -- password-auth host: one prompt authenticates the whole `up` flow
    hosts = { ["100.64.0.5"] = { mux = true } },
}
