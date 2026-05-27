return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      -- map Java to google-java-format
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.java = {}
      -- Add your filetype mappings
      opts.formatters_by_ft.tex = { "tex-fmt" }
      opts.formatters_by_ft.plaintex = { "tex-fmt" }
      opts.formatters_by_ft.latex = { "tex-fmt" }
      -- conform hands formatting off to jdtls
      opts.lsp_fallback = true
      -- Add your custom command paths
      opts.formatters = opts.formatters or {}
    end,
  },
}
