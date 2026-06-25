-------------------------------------------------------------------------------
-- Options
-------------------------------------------------------------------------------

vim.g.did_install_default_menus = 1           -- avoid stupid menu.vim (saves ~100ms)
vim.g.loaded_netrwPlugin = 0                  -- Disable netrw. 🚮 (comment from justinmk)
vim.opt.shortmess:append("I")                 -- Disable start menu
vim.opt.completeopt = 'menu,menuone,noselect' -- disable built-in completion

vim.g.mapleader = " "                         -- leader key (Space)
vim.o.guicursor = ""                          -- use block cursor
vim.o.tabstop = 4                             -- tab display width
vim.o.shiftwidth = 4                          -- indent width
vim.o.softtabstop = -1                        -- follow shiftwidth
vim.o.expandtab = true                        -- tabs -> spaces
vim.o.smartindent = true                      -- auto-indent new lines
vim.o.relativenumber = true                   -- relative line numbers
vim.o.number = true                           -- absolute current line number
vim.o.wrap = false                            -- disable line wrapping
vim.o.scrolloff = 4                           -- keep context around cursor
vim.o.hlsearch = false                        -- don't persist search highlight
vim.o.incsearch = true                        -- incremental search
vim.o.ignorecase = true                       -- case-insensitive search
vim.o.smartcase = true                        -- smart case when uppercase used
vim.o.updatetime = 1000                       -- slower idle update events
vim.o.conceallevel = 0                        -- show concealed text plainly
vim.o.lazyredraw = true                       -- skip some intermediate redraws

vim.o.colorcolumn = "+0"                      -- highlight at textwidth
vim.o.textwidth = 80                          -- preferred line width
vim.o.signcolumn = "yes"                      -- always show sign column

vim.o.swapfile = false                        -- disable swap files
vim.o.backup = false                          -- disable backup files
vim.o.undofile = true                         -- persistent undo

-- vim.o.undodir = os.getenv("HOME") .. "/.vim/undodir" -- undo file directory
vim.opt.path:append({ "/usr/lib/gcc/**/include", "**" })

vim.o.clipboard = "unnamedplus"    -- use system clipboard
vim.o.ruler = false                -- hide ruler
vim.o.showcmd = false              -- hide partial command display
vim.o.showmode = false             -- hide default mode text
vim.opt.spelllang = { "en", "es" } -- spellcheck languages

-- temporal
vim.o.wrap = true      -- wrap
vim.o.linebreak = true -- "inteligent" wrap

-------------------------------------------------------------------------------
-- Diagnostics
-------------------------------------------------------------------------------
vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    underline = false,
    update_in_insert = false,
    severity_sort = true,
})

-------------------------------------------------------------------------------
-- Remaps and other stuff
-------------------------------------------------------------------------------
vim.keymap.set("n", "<leader><leader>", vim.lsp.buf.format)
vim.keymap.set("v", "<leader>p", [["_dP]])
vim.keymap.set("n", "<C-k>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cnext<CR>zz")
vim.keymap.set("c", "wq", "x")
vim.keymap.set("x", "<leader>e", "y:echo <C-r>\"<cr>gv")
vim.keymap.set("n", "<leader>c", "1z=")
vim.keymap.set('n', '<bs>', function()
    vim.diagnostic.config({ virtual_lines = not vim.diagnostic.config().virtual_lines })
end)

vim.keymap.set('n', '<leader>e', ":Oil<cr>")
vim.keymap.set('t', '<Esc>', [[<C-\><C-N>]])

-- Write a typst image func for the last screen capture
vim.keymap.set('n', '<leader>ls', function()
    -- configuration:
    local source_dir = os.getenv("HOME") .. "/Pictures/Screenshots/"
    local dest_dir = "images"

    local handle = io.popen("ls -t " .. source_dir .. " | head -n 1")
    if (handle) then
        local filename = handle:read("*a")
        handle:close()
        filename = string.gsub(filename, "%s+", "")
        os.execute("mkdir -p " .. dest_dir)
        os.execute(string.format("cp '%s/%s' '%s/'", source_dir, filename, dest_dir))
        vim.api.nvim_put({ "#image(\"images/" .. filename .. "\")" }, 'c', false, true)
    end
end)

-- bold and italic for typst
vim.keymap.set('x', '<C-b>', [[c**<esc>P]])
vim.keymap.set('x', '<C-i>', [[c__<esc>P]])

-- pickers
vim.keymap.set('n', '<Leader>f/', '<Cmd>Pick history scope="/"<CR>', { desc = '"/" history' })
vim.keymap.set('n', '<Leader>f:', '<Cmd>Pick history scope=":"<CR>', { desc = '":" history' })
vim.keymap.set('n', '<Leader>fC', '<Cmd>Pick git_commits path="%"<CR>', { desc = 'Commits (buf)' })
vim.keymap.set('n', '<Leader>fD', '<Cmd>Pick diagnostic scope="current"<CR>', { desc = 'Diagnostic buffer' })
vim.keymap.set('n', '<Leader>fG', '<Cmd>Pick grep pattern="<cword>"<CR>', { desc = 'Grep current word' })
vim.keymap.set('n', '<Leader>fa', '<Cmd>Pick git_hunks scope="staged"<CR>', { desc = 'Added hunks (all)' })
vim.keymap.set('n', '<Leader>fb', '<Cmd>Pick buffers<CR>', { desc = 'Buffers' })
vim.keymap.set('n', '<Leader>fc', '<Cmd>Pick git_commits<CR>', { desc = 'Commits (all)' })
vim.keymap.set('n', '<Leader>fd', '<Cmd>Pick diagnostic scope="all"<CR>', { desc = 'Diagnostic workspace' })
vim.keymap.set('n', '<Leader>ff', '<Cmd>Pick files<CR>', { desc = 'Files' })
vim.keymap.set('n', '<Leader>fg', '<Cmd>Pick grep_live<CR>', { desc = 'Grep live' })
vim.keymap.set('n', '<Leader>fh', '<Cmd>Pick help<CR>', { desc = 'Help tags' })
vim.keymap.set('n', '<Leader>fr', '<Cmd>Pick resume<CR>', { desc = 'Resume' })

-------------------------------------------------------------------------------
-- Plugins
-------------------------------------------------------------------------------

vim.pack.add({
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/stevearc/oil.nvim",
    "https://github.com/nvim-mini/mini.pick",
    "https://github.com/nvim-mini/mini.extra",
    "https://github.com/wakatime/vim-wakatime",
    "https://github.com/chomosuke/typst-preview.nvim",
    "https://github.com/sainnhe/gruvbox-material",
    {
        src = "https://github.com/saghen/blink.cmp",
        version = vim.version.range("^1"),
    },
    -- "https://github.com/nvim-treesitter/nvim-treesitter",
})

-------------------------------------------------------------------------------
-- Plugin setup
-------------------------------------------------------------------------------
require 'typst-preview'.setup {
    dependencies_bin = { ['tinymst'] = 'tinymst' }
}

require 'mini.extra'.setup()
require 'mini.pick'.setup()
require 'oil'.setup()

require('blink.cmp').setup {
    keymap = {
        preset = 'enter',
        ['<Tab>'] = { 'show', 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
    },
    completion = {
        trigger = {
            show_on_keyword = false,
            show_on_trigger_character = true,
        },
    },
    sources = {
        default = { 'lsp', 'path', 'buffer' },
    },
}

-- require 'nvim-treesitter'.setup()

-- vim.api.nvim_create_autocmd('FileType', {
--     callback = function()
--         pcall(vim.treesitter.start)
--     end,
-- })

-------------------------------------------------------------------------------
-- Misc stuff
-------------------------------------------------------------------------------
require('vim._core.ui2').enable() -- enable ui2 messages

vim.g.gruvbox_material_background = 'hard'
vim.g.gruvbox_material_disable_italic_comment = 1
vim.g.gruvbox_material_transparent_background = 2
vim.cmd.colorscheme("gruvbox-material")

-- Return to last position when opening a file
vim.api.nvim_create_autocmd('BufReadPost', {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        if mark[1] > 1 and mark[1] <= vim.api.nvim_buf_line_count(0) then
            vim.api.nvim_win_set_cursor(0, mark)
        end
    end,
})

-- Don't open pdf with nvim
vim.api.nvim_create_autocmd("BufReadCmd", {
    pattern = "*.pdf",
    callback = function(ev)
        vim.fn.jobstart({ "zathura", ev.file }, { detach = true })
        vim.cmd.quit()
    end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "*.c", "*.h" },
    callback = function()
        vim.opt_local.tabstop = 8
        vim.opt_local.shiftwidth = 8
        vim.opt_local.softtabstop = -1
        vim.bo.filetype = "c"
    end,
})

vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
    pattern = { "*.html", "*.css" },
    callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.softtabstop = -1
    end,
})

-------------------------------------------------------------------------------
-- LSP
-------------------------------------------------------------------------------

vim.lsp.config('tinymist', {
    settings = { formatterMode = 'typstyle' }
})

vim.lsp.config('lua_ls', {
    settings = {
        Lua = {
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true), }
        }
    }
})

vim.lsp.enable({
    'clangd',
    'tinymist',
    'lua_ls',
    'bashls',
    'html',
    'jdtls',
    'zls',
    'rust_analyzer',
})
