function Github_make(user, repo, branch, artifact)
    return {
        url = "https://github.com/" .. user .. "/" .. repo .. "/archive/refs/heads/" .. branch .. ".tar.gz",
        name = repo .. ".tar.gz",
        last_modified_cmd = "curl -s https://api.github.com/repos/" .. user .. "/" .. repo .. "/commits/" .. branch .. " -I | grep -i last-modified",
        build = "tar -xzf " .. repo .. ".tar.gz && cp -fr " .. repo .. "-" .. branch .. "/* . && make",
        artifact = artifact,
    }
end
