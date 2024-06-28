local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local alnavGroup = augroup('alnav', {})
local yank_group = augroup('HighlightYank', {})


vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.incsearch = true

vim.opt.termguicolors = true

-- make the search not case sensitive unless there's uppercase in the search itself
vim.o.ignorecase = true
vim.o.smartcase = true

-- avoiding highlighting search
vim.o.hlsearch = false

-- function to activate highlighting if i really wanted to
function search_with_highlight(pattern)
    vim.o.hlsearch = true
    vim.fn.search(pattern)
end

-- Function to disable search highlighting
function disable_search_highlight()
    vim.o.hlsearch = false
end

-- Mapeo para llamar a la función search_with_highlight
vim.api.nvim_set_keymap('n', '<leader>/', '<cmd>lua search_with_highlight(vim.fn.input("Search: "))<CR>', { noremap = true, silent = true })

-- Automatically disable search highlighting when exiting search mode
vim.api.nvim_exec([[
augroup ClearSearchHighlight
  autocmd!
  autocmd CmdlineLeave : set nohlsearch
augroup END
]], false)

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.api.nvim_set_var('terminal_scrollback_buffer_size', 30000)

vim.api.nvim_create_user_command('W', 'w', {})
vim.api.nvim_create_user_command('Q', 'q', {})

autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 40,
        })
    end,
})
autocmd({"BufWritePre"}, {
    group = alnavGroup,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

-- Configuration for vim-mergetool
vim.g.mergetool_layout = 'LmR'
vim.g.mergetool_prefer_revision = 'local'

vim.g.mergetool_stealth = 1
