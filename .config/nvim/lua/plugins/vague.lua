vim.pack.add({"https://github.com/vague-theme/vague.nvim"})

require('vague').setup({
  transparent = true,
  colors = {
    bg       = '#0d0d0f',  -- deep charcoal black
    fg       = '#e8e8f0',  -- off-white with blue tint
    comment  = '#555560',  -- mid grey
    black    = '#1a1a1f',
    gray     = '#2e2e36',
    silver   = '#a0a0ae',  -- lighter mid grey
  }
})
vim.cmd('colorscheme vague')


