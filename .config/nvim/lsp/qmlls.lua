--@type vim.lsp.Config
return {
  cmd = { 
    'qmlls', 
    '-I', '/usr/lib/qt6/qml' -- Path to Qt/Quickshell modules
  },
  filetypes = { 'qml' },
  root_markers = { '.git', 'qmldir' },
}

