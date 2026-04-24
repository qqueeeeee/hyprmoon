-- ── LSP ENABLE ───────────────────────────────────────────────────────
vim.lsp.enable({ 'pyright', 'ts_ls', 'lua_ls', 'clangd' })

-- ── COMPLETION + KEYMAPS ON ATTACH ───────────────────────────────────
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    -- native completion
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_completion) then
      vim.opt.completeopt = { 'menu', 'menuone', 'noinsert', 'fuzzy', 'popup' }
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
      vim.keymap.set('i', '<C-Space>', vim.lsp.completion.get, { buffer = ev.buf })
    end

    -- keymaps
    local map = function(keys, fn) vim.keymap.set('n', keys, fn, { buffer = ev.buf }) end
    map('gd',         vim.lsp.buf.definition)
    map('gr',         vim.lsp.buf.references)
    map('K',          vim.lsp.buf.hover)
    map('<leader>rn', vim.lsp.buf.rename)
    map('<leader>ca', vim.lsp.buf.code_action)
    map('<leader>lf', vim.lsp.buf.format)
    map('[d',         vim.diagnostic.goto_prev)
    map(']d',         vim.diagnostic.goto_next)
  end
})

-- ── DIAGNOSTICS ──────────────────────────────────────────────────────
vim.diagnostic.config({
  virtual_text = true,
  virtual_lines = { current_line = true },
  float = { border = 'rounded' },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '✦',
      [vim.diagnostic.severity.WARN]  = '⊹',
      [vim.diagnostic.severity.INFO]  = '⭒',
      [vim.diagnostic.severity.HINT]  = '◈',
    }
  },
})
