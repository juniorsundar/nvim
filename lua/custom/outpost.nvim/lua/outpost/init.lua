local M = {}

local REPO = "juniorsundar/outpost-builds"

local tunnels = {}

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
    return "nvim-portable-" .. platform .. ".tar.gz"
end

local function asset_url(tag, asset)
    return string.format("https://github.com/%s/releases/download/%s/%s", REPO, tag, asset)
end

local function latest_tag(callback)
    vim.system({
        "curl",
        "-fsSL",
        "https://api.github.com/repos/" .. REPO .. "/releases/latest",
    }, { text = true }, function(result)
        vim.schedule(function()
            if result.code ~= 0 then
                callback(nil, result.stderr or "failed to resolve latest release")
                return
            end

            local ok, decoded = pcall(vim.json.decode, result.stdout)

            if not ok or type(decoded) ~= "table" or not decoded.tag_name then
                callback(nil, "could not parse latest release response")
                return
            end

            callback(decoded.tag_name, nil)
        end)
    end)
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

-- Resolve a cached archive for the platform/tag, downloading only when the
-- cached copy is missing or fails checksum verification. Multiple remote
-- hosts therefore share a single download.
local function ensure_archive(platform, tag, callback)
    local asset = asset_name(platform)
    local cache_dir = vim.fs.joinpath(vim.fn.stdpath "cache", "outpost", "downloads")

    local archive_path = vim.fs.joinpath(cache_dir, asset)
    local checksum_path = vim.fs.joinpath(cache_dir, asset .. ".sha256")

    local function get_archive(cb)
        download(asset_url(tag, asset), archive_path, function(_, err)
            if err then
                cb(nil, err)
                return
            end

            verify_sha256(archive_path, checksum_path, function(ok, result)
                if not ok then
                    cb(nil, result)
                    return
                end

                cb(archive_path, nil)
            end)
        end)
    end

    download(asset_url(tag, asset .. ".sha256"), checksum_path, function(_, err)
        if err then
            callback(nil, err)
            return
        end

        if not vim.uv.fs_stat(archive_path) then
            get_archive(callback)
            return
        end

        verify_sha256(archive_path, checksum_path, function(ok)
            if ok then
                callback(archive_path, nil)
                return
            end

            get_archive(callback)
        end)
    end)
end

local function remote_version(host, callback)
    vim.system({
        "ssh",
        host,
        [[cat "$HOME/.cache/outpost/install/version" 2>/dev/null || exit 1]],
    }, { text = true }, function(result)
        vim.schedule(function()
            if result.code == 0 then
                callback(vim.trim(result.stdout))
            else
                callback(nil)
            end
        end)
    end)
end

local function install_remote(host, asset, tag, callback)
    local command = string.format(
        [[
set -eu
INSTALL="$HOME/.cache/outpost/install"
ARCHIVE="$HOME/.cache/outpost/downloads/%s"

rm -rf "$INSTALL/current"
mkdir -p "$INSTALL/current" "$HOME/.cache/outpost/downloads"
tar -xzf "$ARCHIVE" -C "$INSTALL/current"
printf '%%s\n' '%s' > "$INSTALL/version"
]],
        asset,
        tag
    )

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

            callback(true, nil)
        end)
    end)
end

local function install(host, platform, tag, callback)
    ensure_archive(platform, tag, function(archive, err)
        if not archive then
            callback(false, err)
            return
        end

        vim.system({
            "ssh",
            host,
            "mkdir -p ~/.cache/outpost/downloads",
        }, { text = true }, function(mkdir_result)
            vim.schedule(function()
                if mkdir_result.code ~= 0 then
                    callback(false, mkdir_result.stderr or "remote mkdir failed")
                    return
                end

                local remote_path = "~/.cache/outpost/downloads/" .. vim.fs.basename(archive)

                upload(host, archive, remote_path, function(ok, upload_err)
                    if not ok then
                        callback(false, upload_err)
                        return
                    end

                    install_remote(host, vim.fs.basename(archive), tag, function(ok, install_err)
                        if not ok then
                            callback(false, install_err)
                            return
                        end

                        callback(true, nil)
                    end)
                end)
            end)
        end)
    end)
end

local function start_remote_server(host, callback)
    local command = [[
SOCKET="$HOME/.cache/outpost/run/nvim.sock"
NVIM="$HOME/.cache/outpost/install/current/bin/nvim"

mkdir -p "$HOME/.cache/outpost/run"

if [ -S "$SOCKET" ] && "$NVIM" --server "$SOCKET" --remote-expr '1' >/dev/null 2>&1; then
    exit 0
fi

rm -f "$SOCKET"

nohup "$NVIM" \
  --headless \
  --listen "$SOCKET" \
  >"$HOME/.cache/outpost/run/nvim.log" \
  2>&1 </dev/null &

sleep 1

test -S "$SOCKET"
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
    local existing = tunnels[host]

    if existing then
        existing.process:kill(15)
        tunnels[host] = nil
    end

    local local_socket = vim.fs.joinpath(vim.fn.stdpath "cache", "outpost", "run", "nvim.sock")

    vim.fn.mkdir(vim.fs.dirname(local_socket), "p")
    vim.fn.delete(local_socket)

    local remote_socket = remote_home .. "/.cache/outpost/run/nvim.sock"

    local process = vim.system {
        "ssh",
        "-N",
        "-o",
        "ExitOnForwardFailure=yes",
        "-L",
        local_socket .. ":" .. remote_socket,
        host,
    }

    vim.defer_fn(function()
        if vim.uv.fs_stat(local_socket) then
            tunnels[host] = {
                process = process,
                socket = local_socket,
            }

            callback(true, tunnels[host])
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

local function connect_remote(host, remote_home)
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
end

local function resolve_remote(host, callback)
    vim.system({
        "ssh",
        host,
        [[printf '%s\n%s\n%s\n' "$(uname -s)" "$(uname -m)" "$HOME"]],
    }, { text = true }, function(result)
        vim.schedule(function()
            if result.code ~= 0 then
                callback(nil, result.stderr or "ssh probe failed")
                return
            end

            local lines = vim.split(vim.trim(result.stdout), "\n")
            local remote_home = lines[3]

            local platform, err = normalize_platform(lines[1], lines[2])

            if not platform then
                callback(nil, err)
                return
            end

            callback({
                platform = platform,
                home = remote_home,
            }, nil)
        end)
    end)
end

function M.probe(host)
    resolve_remote(host, function(remote, err)
        if not remote then
            vim.notify(err, vim.log.levels.ERROR)
            return
        end

        latest_tag(function(tag, tag_err)
            if not tag then
                vim.notify(tag_err, vim.log.levels.ERROR)
                return
            end

            remote_version(host, function(installed)
                if installed == tag then
                    connect_remote(host, remote.home)
                    return
                end

                if installed then
                    vim.notify(
                        string.format(
                            "outpost: update available (%s -> %s). Run :OutpostUpdate %s",
                            installed,
                            tag,
                            host
                        ),
                        vim.log.levels.WARN
                    )
                    return
                end

                vim.notify("outpost: installing Neovim " .. tag .. " on " .. host)
                install(host, remote.platform, tag, function(ok, install_err)
                    if not ok then
                        vim.notify(install_err, vim.log.levels.ERROR)
                        return
                    end

                    connect_remote(host, remote.home)
                end)
            end)
        end)
    end)
end

function M.update(host)
    resolve_remote(host, function(remote, err)
        if not remote then
            vim.notify(err, vim.log.levels.ERROR)
            return
        end

        latest_tag(function(tag, tag_err)
            if not tag then
                vim.notify(tag_err, vim.log.levels.ERROR)
                return
            end

            remote_version(host, function(installed)
                if installed == tag then
                    vim.notify("outpost: " .. host .. " already on " .. tag)
                    connect_remote(host, remote.home)
                    return
                end

                if installed then
                    vim.notify(string.format("outpost: updating %s (%s -> %s)", host, installed, tag))
                else
                    vim.notify("outpost: installing Neovim " .. tag .. " on " .. host)
                end

                install(host, remote.platform, tag, function(ok, install_err)
                    if not ok then
                        vim.notify(install_err, vim.log.levels.ERROR)
                        return
                    end

                    connect_remote(host, remote.home)
                end)
            end)
        end)
    end)
end

function M.setup()
    local function command_opts()
        return {
            nargs = 1,
        }
    end

    vim.api.nvim_create_user_command("Outpost", function(opts)
        M.probe(opts.args)
    end, command_opts())

    vim.api.nvim_create_user_command("OutpostUpdate", function(opts)
        M.update(opts.args)
    end, command_opts())
end

return M
