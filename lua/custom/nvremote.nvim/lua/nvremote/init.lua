local M = {}

local function normalize_platform(os_name, arch)
    if os_name ~= "Linux" then
        return nil, "unsupported operating system: " .. os_name
    end

    local arch_map = {
        x86_64 = "x86_64",
        amd64 = "x86_64",

        aarch64 = "aarch64",
        arm64 = "aarch64",
    }

    local normalized_arch = arch_map[arch]

    if not normalized_arch then
        return nil, "unsupported architecture: " .. arch
    end

    return "linux-" .. normalized_arch
end

local function asset_name(platform)
    return "nvremote-nvim-" .. platform .. ".tar.gz"
end

local function asset_url(tag, asset)
    return string.format("https://github.com/juniorsundar/neovim/releases/download/%s/%s", tag, asset)
end

local function download(url, path, callback)
    vim.fn.mkdir(vim.fs.dirname(path), "p")

    vim.system({
        "curl",
        "-fL",
        "--output",
        path,
        url,
    }, { text = true }, function(result)
        vim.schedule(function()
            if result.code ~= 0 then
                callback(nil, result.stderr or "download failed")
                return
            end

            callback(path, nil)
        end)
    end)
end

local function upload(host, local_path, remote_path, callback)
    vim.system({
        "scp",
        local_path,
        host .. ":" .. remote_path,
    }, { text = true }, function(result)
        vim.schedule(function()
            if result.code ~= 0 then
                callback(false, result.stderr or "upload failed")
                return
            end

            callback(true, nil)
        end)
    end)
end

local function verify_sha256(archive_path, checksum_path, callback)
    vim.system({
        "sha256sum",
        "-c",
        checksum_path,
    }, {
        text = true,
        cwd = vim.fs.dirname(archive_path),
    }, function(result)
        vim.schedule(function()
            if result.code ~= 0 then
                callback(false, result.stderr or result.stdout or "checksum verification failed")
                return
            end

            callback(true, result.stdout)
        end)
    end)
end

local function install_remote(host, asset, callback)
    local archive = "~/.cache/nvremote/downloads/" .. asset
    local install_dir = "~/.cache/nvremote/install/current"

    local command =
        string.format("rm -rf %s && mkdir -p %s && tar -xzf %s -C %s", install_dir, install_dir, archive, install_dir)

    vim.system({
        "ssh",
        host,
        command,
    }, { text = true }, function(result)
        vim.schedule(function()
            if result.code ~= 0 then
                callback(false, result.stderr or "remote install failed")
                return
            end

            callback(true, install_dir)
        end)
    end)
end

local function start_remote_server(host, callback)
    local command = [[
mkdir -p ~/.cache/nvremote/run
rm -f ~/.cache/nvremote/run/nvim.sock

nohup ~/.cache/nvremote/install/current/bin/nvim \
  --headless \
  --listen ~/.cache/nvremote/run/nvim.sock \
  >~/.cache/nvremote/run/nvim.log \
  2>&1 </dev/null &

sleep 1

test -S ~/.cache/nvremote/run/nvim.sock
]]

    vim.system({
        "ssh",
        host,
        command,
    }, { text = true }, function(result)
        vim.schedule(function()
            if result.code ~= 0 then
                callback(false, result.stderr or "failed to start remote Neovim")
                return
            end

            callback(true, nil)
        end)
    end)
end

local function start_tunnel(host, remote_home, callback)
    local local_socket = vim.fs.joinpath(vim.fn.stdpath "cache", "nvremote", "run", "nvim.sock")

    vim.fn.mkdir(vim.fs.dirname(local_socket), "p")
    vim.fn.delete(local_socket)

    local remote_socket = remote_home .. "/.cache/nvremote/run/nvim.sock"

    local process = vim.system {
        "ssh",
        "-N",
        "-L",
        local_socket .. ":" .. remote_socket,
        host,
    }

    vim.defer_fn(function()
        if vim.uv.fs_stat(local_socket) then
            callback(true, {
                process = process,
                socket = local_socket,
            })
        else
            process:kill(15)
            callback(false, "SSH tunnel did not create local socket")
        end
    end, 1000)
end

local function connect_rpc(socket)
    local channel = vim.fn.sockconnect("pipe", socket, { rpc = true })

    if channel <= 0 then
        return nil, "failed to connect to remote Neovim RPC"
    end

    return channel, nil
end

local function remote_installed(host, callback)
    vim.system({
        "ssh",
        host,
        "test -x ~/.cache/nvremote/install/current/bin/nvim",
    }, { text = true }, function(result)
        vim.schedule(function()
            callback(result.code == 0)
        end)
    end)
end

function M.probe(host)
    vim.system({
        "ssh",
        host,
        [[printf '%s\n%s\n%s\n' "$(uname -s)" "$(uname -m)" "$HOME"]],
    }, { text = true }, function(result)
        vim.schedule(function()
            if result.code ~= 0 then
                vim.notify(result.stderr or "ssh probe failed", vim.log.levels.ERROR)
                return
            end

            local lines = vim.split(vim.trim(result.stdout), "\n")
            local remote_home = lines[3]
            vim.notify("remote home: " .. remote_home)

            local platform, err = normalize_platform(lines[1], lines[2])

            if not platform then
                vim.notify(err, vim.log.levels.ERROR)
                return
            end

            local asset = asset_name(platform)
            local url = asset_url("nvremote-test-3", asset)

            local cache_dir = vim.fs.joinpath(vim.fn.stdpath "cache", "nvremote", "downloads")

            local path = vim.fs.joinpath(cache_dir, asset)

            download(url, path, function(downloaded, err)
                if not downloaded then
                    vim.notify(err, vim.log.levels.ERROR)
                    return
                end

                local checksum_asset = asset .. ".sha256"
                local checksum_url = asset_url("nvremote-test-3", checksum_asset)
                local checksum_path = vim.fs.joinpath(cache_dir, checksum_asset)

                download(checksum_url, checksum_path, function(_, checksum_err)
                    if checksum_err then
                        vim.notify(checksum_err, vim.log.levels.ERROR)
                        return
                    end

                    verify_sha256(path, checksum_path, function(ok, verify_result)
                        if not ok then
                            vim.notify(verify_result, vim.log.levels.ERROR)
                            return
                        end

                        local remote_dir = "~/.cache/nvremote/downloads"
                        local remote_path = remote_dir .. "/" .. asset

                        vim.system({
                            "ssh",
                            host,
                            "mkdir -p " .. remote_dir,
                        }, { text = true }, function(mkdir_result)
                            vim.schedule(function()
                                if mkdir_result.code ~= 0 then
                                    vim.notify(mkdir_result.stderr or "remote mkdir failed", vim.log.levels.ERROR)
                                    return
                                end

                                upload(host, path, remote_path, function(ok, upload_err)
                                    if not ok then
                                        vim.notify(upload_err, vim.log.levels.ERROR)
                                        return
                                    end

                                    install_remote(host, asset, function(ok, result)
                                        if not ok then
                                            vim.notify(result, vim.log.levels.ERROR)
                                            return
                                        end

                                        start_remote_server(host, function(started, start_err)
                                            if not started then
                                                vim.notify(start_err, vim.log.levels.ERROR)
                                                return
                                            end

                                            start_tunnel(host, remote_home, function(ok, tunnel)
                                                if not ok then
                                                    vim.notify(tunnel, vim.log.levels.ERROR)
                                                    return
                                                end

                                                local channel, rpc_err = connect_rpc(tunnel.socket)

                                                if not channel then
                                                    vim.notify(rpc_err, vim.log.levels.ERROR)
                                                    return
                                                end

                                                local version = vim.rpcrequest(
                                                    channel,
                                                    "nvim_exec_lua",
                                                    [[
                                                            local v = vim.version()
                                                            return string.format(
                                                                "%d.%d.%d%s",
                                                                v.major,
                                                                v.minor,
                                                                v.patch,
                                                                v.prerelease and "-dev" or ""
                                                            )
                                                            ]],
                                                    {}
                                                )

                                                vim.notify("remote Neovim: " .. version)
                                            end)
                                        end)
                                    end)
                                end)
                            end)
                        end)
                    end)
                end)
            end)
        end)
    end)
end

function M.setup()
    vim.api.nvim_create_user_command("NvRemote", function(opts)
        M.probe(opts.args)
    end, {
        nargs = 1,
        complete = "file",
    })
end

return M
