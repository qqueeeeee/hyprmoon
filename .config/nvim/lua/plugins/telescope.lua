local hooks = function(ev)
  local name, kind = ev.data.spec.name, ev.data.kind
  if name == 'telescope-fzf-native.nvim' and (kind == 'install' or kind == 'update') then
    vim.system({ 'make' }, { cwd = ev.data.path }):wait()
  end
end

vim.api.nvim_create_autocmd('PackChanged', { callback = hooks })

vim.pack.add({
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/nvim-telescope/telescope-fzf-native.nvim',
})

require('telescope').setup({
  defaults = {
    border = true,
    borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
    prompt_prefix = '⭒ ',
    selection_caret = '◈ ',
    color_devicons = true,
		preview = {
			treesitter = false,
		}
  }
})

require('telescope').load_extension('fzf')

local tb = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', tb.find_files)
vim.keymap.set('n', '<leader>fg', tb.live_grep)
vim.keymap.set('n', '<leader>fb', tb.buffers)
vim.keymap.set('n', '<leader>fh', tb.help_tags)
vim.keymap.set('n', '<leader>fc', function()
  tb.find_files({ cwd = vim.fn.stdpath('config') })
end)

vim.keymap.set('n', '<leader>fp', function()
  tb.find_files({
    cwd = '~/projects',
		max_depth = 0,
  })
end)
