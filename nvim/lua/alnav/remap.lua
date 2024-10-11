
vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
--vim.api.nvim_set_keymap('n', '<leader>q', ':q<CR>', { noremap = true, silent = true })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set("n", "Q", "<nop>")

function Copy_increment_paste_line()
  -- Copiar la línea actual
  vim.cmd('normal! yy')

  -- Pegar la línea copiada debajo de la actual sin mover el cursor primero
  vim.cmd('normal! P')

  -- Mover el cursor hacia abajo para estar en la línea pegada
  vim.cmd('normal! j')

  -- Obtener la posición actual (que ahora debería ser la línea pegada debajo de la original)
  local line_num = vim.api.nvim_win_get_cursor(0)[1]

  -- Obtener el contenido de la línea pegada
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]

  -- Incrementar todos los números encontrados en la línea
  local incremented_line = line:gsub('(%d+)', function(n)
      return tostring(tonumber(n) + 1)
  end)

  -- Reemplazar la línea pegada con la versión incrementada
  vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, {incremented_line})
end

-- Mapear @p para llamar a Copy_increment_paste_line()
vim.keymap.set('n', '@p', ':lua Copy_increment_paste_line()<CR>', {noremap = true, silent = true})

vim.api.nvim_set_keymap('n', '@a', '<C-a>', {noremap = true, silent = true})

-- Esc para volver a normal mode en terminal
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  command = "tnoremap <buffer> <Esc> <C-\\><C-n>"
})

local function setup_refactor_keymaps()
    local buf = vim.api.nvim_get_current_buf()
    local buf_ft = vim.api.nvim_buf_get_option(buf, 'filetype')
    if buf_ft == 'java' then
        -- Aquí, configura los mapeos de teclas específicos para Java
        --vim.api.nvim_buf_set_keymap(3, 'v', '<leader>xm', '<Esc>:lua require(\'jdtls\').extract_method(true)<CR>', { noremap = true, silent = true })
    else
        vim.keymap.set("x", "<leader>xm", function() require('refactoring').refactor('Extract Function') end)
    end
end

--vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
      -- Enable completion triggered by <c-x><c-o>
      vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
      local opts = { buffer = ev.buf }
      vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
      vim.keymap.set("n", "gi", function() vim.lsp.buf.implementation() end, opts)
      vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
      vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
      vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
      vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
      vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
      vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
      vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
      vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
      vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)


      setup_refactor_keymaps()

      vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
  end
})
