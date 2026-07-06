--[[
    ~ pm. A package manager by Hugo Coto.
]] --

-- Add ~/.config/pm/ to the path
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.config/pm/?.lua"

-- Add ~/.config/pm/ to the path
Build = {
    path = os.getenv("HOME") .. "/.local/share/pm/cache/"
}

--[[
    Package possible fields:
    - url
    - build
    - name
]] --
Packages = {
    {
        -- pm bootstraping. Keep pm updated.
        url = "https://github.com/hugoocoto/pm/releases/download/nightly/pm.tar.gz",
        name = pm,
        build = "tar -xzf pm.tar.gz && make && mv ./pm ~/.local/bin/pm",
    },
}
