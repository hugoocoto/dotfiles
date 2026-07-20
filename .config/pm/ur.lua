local https = require("ssl.https")
local base = "https://raw.githubusercontent.com/hugoocoto/pm-user-repository/refs/heads/main"

--- Fetches a Lua table from a URL.
local function Fetch(params)
    assert(type(params) == "table", "Expects a table of parameters")
    assert(type(params.user) == "string", "Requires params.user as a string")
    assert(type(params.file) == "string", "Requires params.file as a string")

    local url = base .. "/" .. params.user .. "/" .. params.file

    -- Download the raw content
    local body, statusOrErr, headers = https.request(url)
    if not body then
        error(("Request failed for %s (%s)"):format(url, tostring(statusOrErr)))
    end
    if type(statusOrErr) == "number" and statusOrErr ~= 200 then
        error(("HTTP %d fetching %s"):format(statusOrErr, url))
    end

    -- Compile as a Lua chunk (text-only mode blocks bytecode injection)
    local chunkName = "@remote:" .. url
    local chunk, loadErr = load(body, chunkName, "t")
    if not chunk then
        error(("Failed to parse Lua from %s: %s"):format(url, loadErr))
    end

    -- Execute it and capture the returned table
    local ok, result = pcall(chunk)
    if not ok then
        error(("Error executing remote chunk from %s: %s"):format(url, result))
    end
    if type(result) ~= "table" then
        error(("Expected %s to return a table, got %s"):format(url, type(result)))
    end

    return result
end

-- Github: fetch and build a GitHub repo archive.
--
-- To avoid GitHub API rate limiting (60 req/hr unauthenticated),
-- authenticate via the GitHub CLI:
--
--   pacman -S github-cli
--   gh auth login
--
-- This reads your token via `gh auth token` and uses it for API
-- requests, raising the limit to 5000 req/hr. If `gh` is not
-- installed or not authenticated, requests are made without a token
-- (60 req/hr limit).

local function gh_token()
    local f = io.popen("gh auth token 2>/dev/null")
    if not f then return "" end
    local tok = f:read("*a"):gsub("%s+", "")
    f:close()
    return tok
end

local _gh_token = gh_token()
local _auth_flag = _gh_token ~= "" and "-H 'Authorization: token " .. _gh_token .. "'" or ""

function Github(opts)
    local branch = opts.branch or "main"
    local repo = opts.repo
    local extract = repo .. "-" .. branch

    return {
        url               = opts.url or
            ("https://github.com/" .. opts.user .. "/" .. repo .. "/archive/refs/heads/" .. branch .. ".tar.gz"),
        name              = opts.name or (repo .. ".tar.gz"),
        last_modified_cmd = opts.last_modified_cmd or
            ("curl -s " .. _auth_flag .. " https://api.github.com/repos/" .. opts.user .. "/" .. repo .. "/commits/" .. branch .. " -I | grep -i last-modified"),
        build             = "tar xzf " .. repo .. ".tar.gz && cp -fr " .. extract .. "/* . && " .. (opts.cmd or "make"),
        artifact          = opts.artifact or repo,
    }
end

return { Fetch = Fetch, Github = Github }

