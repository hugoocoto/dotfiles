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

return Fetch
