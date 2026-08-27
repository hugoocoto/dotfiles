-- Move image to ~/Downloads (my trash)
swayimg.gallery.on_key("Shift-d", function()
    local image = swayimg.gallery.get_image()
    local filename = image.path:match("([^/]+)$")
    local dest = os.getenv("HOME") .. "/Downloads/" .. filename
    local ok, err = os.execute('mv "' .. image.path .. '" "' .. dest .. '"')
    if not ok then
        print("Move failed: " .. tostring(err))
    end
end)
