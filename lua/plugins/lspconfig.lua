return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      lua_ls = {
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
          },
        },
      },
      ltex = false,
      ltex_ls = false,
      ltex_plus = {
        filetypes = { "markdown", "tex", "text" },
        settings = {
          ltex = {
            language = "en-GB",
          },
        },
      },
      texlab = {
        settings = {
          texlab = {
            chktex = { onOpenAndSave = true, onEdit = true },
            diagnostics = {
              ignoredPatterns = { "Undefined reference" },
            },
          },
        },
      },
    },
    -- This section directly overrides LazyVim's diagnostic defaults
    diagnostics = {
      virtual_text = {
        source = "always", -- Shows source in the line (gutter/end of line)
      },
      float = {
        source = "always", -- Shows source in the hover window (leader + cd)
      },
    },
  },
}
