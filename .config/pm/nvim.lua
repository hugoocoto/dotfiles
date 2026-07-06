return {
    url = "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-arm64.appimage",
    build = [[
        chmod +x nvim-linux-arm64.appimage
        cp -f nvim-linux-arm64.appimage ~/.local/bin/nvim
    ]],
}
