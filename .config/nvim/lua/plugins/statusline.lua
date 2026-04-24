Statusline = {}

Statusline.getMode = function()
  local CTRL_S = vim.api.nvim_replace_termcodes("<C-S>", true, true, true)
  local CTRL_V = vim.api.nvim_replace_termcodes("<C-V>", true, true, true)
  local modes = setmetatable({
    ["n"]      = { name = "N",         hl = "%#MiniStatuslineModeNormal#" },
    ["v"]      = { name = "V",         hl = "%#MiniStatuslineModeVisual#" },
    ["V"]      = { name = "V-LINE",    hl = "%#MiniStatuslineModeVisual#" },
    [CTRL_V]   = { name = "V-BLOCK",   hl = "%#MiniStatuslineModeVisual#" },
    ["s"]      = { name = "SEL",       hl = "%#MiniStatuslineModeVisual#" },
    ["S"]      = { name = "SEL-LINE",  hl = "%#MiniStatuslineModeVisual#" },
    [CTRL_S]   = { name = "SEL-BLOCK", hl = "%#MiniStatuslineModeVisual#" },
    ["i"]      = { name = "I",         hl = "%#MiniStatuslineModeInsert#" },
    ["R"]      = { name = "R",         hl = "%#MiniStatuslineModeReplace#" },
    ["c"]      = { name = "CMD",       hl = "%#MiniStatuslineModeCommand#" },
    ["r"]      = { name = "PROMPT",    hl = "%#MiniStatuslineModeOther#" },
    ["!"]      = { name = "SH",        hl = "%#MiniStatuslineModeOther#" },
    ["t"]      = { name = "TERM",      hl = "%#MiniStatuslineModeOther#" },
  }, { __index = function() return { name = "?", hl = "%#MiniStatuslineModeOther#" } end })
  return modes[vim.fn.mode()]
end

Statusline.build = function()
  local mode     = Statusline.getMode()
  local cwd      = string.format(" %s ", vim.fn.fnamemodify(vim.fn.getcwd(), ":t"))
  local filepath = "%f"
  local modified = "%m%r "
  local eol      = vim.bo.fileformat:upper()
  local enc      = (vim.bo.fileencoding == "" and vim.go.encoding or vim.bo.fileencoding):upper()
  local location = " %l/%L:%-2v "
  local pct      = " %P "

  local tab_icon, width
  if vim.bo.expandtab then
    tab_icon = "SPC:"
    width = vim.bo.shiftwidth
  else
    tab_icon = "TAB:"
    width = vim.bo.tabstop
  end

  return table.concat({
    mode.hl, " ", mode.name, " ",
    "%#MiniStatuslineDevinfo#", cwd,
    "%<",
    "%#MiniStatuslineFilename#", " ", filepath, modified,
    "%#MiniStatuslineInactive#",
    "%=",
    "%#MiniStatuslineFilename#",
    "%Y", " | ", eol, " | ", enc, " | ", tab_icon, width, " ",
    "%#MiniStatuslineFileinfo#", location,
    mode.hl, pct,
  })
end

Statusline.colors = function()
  vim.api.nvim_set_hl(0, 'MiniStatuslineModeNormal',  { fg = '#0d0d0f', bg = '#a0a0ae', bold = true })
  vim.api.nvim_set_hl(0, 'MiniStatuslineModeInsert',  { fg = '#0d0d0f', bg = '#e8e8f0', bold = true })
  vim.api.nvim_set_hl(0, 'MiniStatuslineModeVisual',  { fg = '#0d0d0f', bg = '#555560', bold = true })
  vim.api.nvim_set_hl(0, 'MiniStatuslineModeReplace', { fg = '#0d0d0f', bg = '#555560', bold = true })
  vim.api.nvim_set_hl(0, 'MiniStatuslineModeCommand', { fg = '#0d0d0f', bg = '#2e2e36', bold = true })
  vim.api.nvim_set_hl(0, 'MiniStatuslineModeOther',   { fg = '#a0a0ae', bg = '#1a1a1f', bold = true })
  vim.api.nvim_set_hl(0, 'MiniStatuslineDevinfo',     { fg = '#555560', bg = '#1a1a1f' })
  vim.api.nvim_set_hl(0, 'MiniStatuslineFilename',    { fg = '#a0a0ae', bg = '#0d0d0f' })
  vim.api.nvim_set_hl(0, 'MiniStatuslineFileinfo',    { fg = '#555560', bg = '#0d0d0f' })
  vim.api.nvim_set_hl(0, 'MiniStatuslineInactive',    { fg = '#2e2e36', bg = '#0d0d0f' })
end

Statusline.setup = function()
  Statusline.colors()
  vim.opt.laststatus = 3
  vim.go.statusline = "%!v:lua.Statusline.build()"
  -- reapply on colorscheme change
  vim.api.nvim_create_autocmd('ColorScheme', {
    callback = Statusline.colors
  })
end

return Statusline
