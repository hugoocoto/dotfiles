local registry = "hugoocoto/pm-user-repository"

-- Fetched files are cached in cache_dir, named by their git blob sha (a hash
-- of their content). cache_dir/tree maps every path in the registry to its
-- blob sha at some commit. Each run checks the latest commit with a single
-- request; only when it changed is the tree downloaded again, so only files
-- whose content changed are downloaded again. Offline, the cache is used.
local cache_dir = (os.getenv("XDG_CACHE_HOME") or os.getenv("HOME") .. "/.cache") .. "/pm/ur/"

local function quote(s)
    return "'" .. s:gsub("'", [['\'']]) .. "'"
end

-- curl verifies TLS certificates and host names. LuaSec's https.request
-- doesn't by default, which lets anyone on the network serve code to run.
local function get(url)
    local f = assert(io.popen("curl -sfL --proto =https -m 10 " .. quote(url)))
    local body = f:read("a")
    return f:close() and body or nil
end

local function read_file(name)
    local f = io.open(cache_dir .. name, "rb")
    if not f then return nil end
    local data = f:read("a")
    f:close()
    return data
end

-- Through a temporary file, so an interrupted run can't leave a truncated one.
local function write_file(name, data)
    os.execute("mkdir -p " .. quote(cache_dir))
    local tmp = cache_dir .. name .. ".tmp"
    local f = io.open(tmp, "wb")
    if f and f:write(data) and f:close() then os.rename(tmp, cache_dir .. name) end
end

-- tree: path -> blob sha at `commit`, loaded once per run. When the latest
-- commit can't be resolved (offline) or its tree can't be downloaded (API
-- rate limit), the cached tree is used as it is.
local tree, commit
local function load_tree()
    if tree then return end
    local data = read_file("tree") or ""
    local refs = get("https://github.com/" .. registry .. ".git/info/refs?service=git-upload-pack")
    local latest = refs and refs:match("(" .. ("%x"):rep(40) .. ") refs/heads/main\n")
    if latest and latest ~= data:match("^%x+") then
        local json = get("https://api.github.com/repos/" .. registry .. "/git/trees/" .. latest .. "?recursive=1")
        if json then
            data = latest .. "\n"
            for path, sha in json:gmatch('"path": *"([^"]*)"[^}]-"sha": *"(%x+)"') do
                data = data .. sha .. " " .. path .. "\n"
            end
            write_file("tree", data)
        end
    end
    commit, tree = data:match("^%x+"), {}
    for sha, path in data:gmatch("\n(%x+) ([^\n]+)") do tree[path] = sha end
end

--- Fetches a package definition from the registry and returns its table.
local function Fetch(params)
    assert(type(params) == "table" and type(params.user) == "string" and type(params.file) == "string",
        "ur.Fetch expects { user = string, file = string }")

    load_tree()
    local path = params.user .. "/" .. params.file
    local sha = tree[path]
    local body = sha and read_file(sha)
    if not body then
        -- By commit when known: the CDN can serve a stale copy of the branch URL
        local url = "https://raw.githubusercontent.com/" .. registry .. "/" .. (sha and commit or "main") .. "/" .. path
        body = get(url) or error("ur: can't download " .. url, 2)
        if sha then write_file(sha, body) end
    end

    -- Text-only mode blocks bytecode injection
    local result = assert(load(body, "@ur:" .. path, "t"))()
    assert(type(result) == "table", "ur: " .. path .. " doesn't return a table")
    return result
end

-- Github: fetch and build a GitHub repo archive.
--
-- last_modified_cmd queries the GitHub API: 60 req/hr without a token, 5000
-- with one. The token is read from GH_TOKEN or the GitHub CLI (`gh auth
-- login`) when the command runs, and is passed to curl on stdin so it never
-- shows up in `ps`.
local function Github(opts)
    local branch = opts.branch or "main"
    local repo = opts.repo
    local name = opts.name or (repo .. ".tar.gz")
    local api = "https://api.github.com/repos/" .. opts.user .. "/" .. repo .. "/commits/" .. branch

    return {
        url               = opts.url or
            ("https://github.com/" .. opts.user .. "/" .. repo .. "/archive/refs/heads/" .. branch .. ".tar.gz"),
        name              = name,
        last_modified_cmd = opts.last_modified_cmd or
            ([[t=${GH_TOKEN:-$(gh auth token 2>/dev/null)}; printf %s "${t:+Authorization: token $t}" | curl -sI -H @- ]] ..
                api .. " | grep -i last-modified"),
        build             = "tar xzf " .. name .. " && cp -fr " .. repo .. "-" .. branch .. "/* . && " .. (opts.cmd or "make"),
        artifact          = opts.artifact or repo,
    }
end

return { Fetch = Fetch, Github = Github }
