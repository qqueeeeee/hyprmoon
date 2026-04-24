require('config.globals')
require('config.options')
require('config.keymaps')
require('config.autocmd')

require('plugins.treesitter')
require('plugins.oil')
require('plugins.vague')
require('plugins.mini')
require('plugins.telescope')
require('plugins.mason')
require('config.lsp')

vim.cmd("set completeopt+=noselect")
vim.cmd(":hi statusline guibg=NONE")

