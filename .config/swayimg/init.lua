-- Move the file to ~/Downloads (My trash)
swayimg.gallery.on_key("Shift-D", function()
    local image = swayimg.gallery.get_image()
    local filename = image.path:match("([^/]+)$") -- just the filename
    local dest = os.getenv("HOME") .. "/Downloads/" .. filename
    os.rename(image.path, dest)
end)
