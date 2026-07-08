function Github_make(user, repo, branch, artifact)
    return {
        url = "https://github.com/" .. user .. "/" .. repo .. "/archive/refs/heads/" .. branch .. ".tar.gz",
        name = repo .. ".tar.gz",
        build = "tar -xzf " .. repo .. ".tar.gz && mv " .. repo .. "-" .. branch .. "/* . && make",
        artifact = artifact,
    }
end
