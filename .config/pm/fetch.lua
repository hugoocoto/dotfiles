local https = require("ssl.https")

--- Fetches a Lua table from a URL.
local function Fetch(params)
  assert(type(params) == "table", "Fetch expects a table of parameters")
  local url = params.url
  assert(type(url) == "string", "Fetch requires params.url as a string")

  -- Download the raw content
  local body, statusOrErr, headers = https.request(url)
  if not body then
    error(("Fetch: request failed for %s (%s)"):format(url, tostring(statusOrErr)))
  end
  if type(statusOrErr) == "number" and statusOrErr ~= 200 then
    error(("Fetch: HTTP %d fetching %s"):format(statusOrErr, url))
  end

  -- Compile as a Lua chunk 
  local chunkName = "@remote:" .. url
  local chunk, loadErr = load(body, chunkName, "t")
  if not chunk then
    error(("Fetch: failed to parse Lua from %s: %s"):format(url, loadErr))
  end

  -- Execute it and capture the returned table
  local ok, result = pcall(chunk)
  if not ok then
    error(("Fetch: error executing remote chunk from %s: %s"):format(url, result))
  end
  if type(result) ~= "table" then
    error(("Fetch: expected %s to return a table, got %s"):format(url, type(result)))
  end

  return result
end
