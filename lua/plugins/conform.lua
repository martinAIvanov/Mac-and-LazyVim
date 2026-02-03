return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      -- Add your filetype mappings
      opts.formatters_by_ft.tex = { "tex-fmt" }
      opts.formatters_by_ft.plaintex = { "tex-fmt" }
      opts.formatters_by_ft.latex = { "tex-fmt" }
      -- Do NOT fall back to LSP formatting
      opts.lsp_fallback = false
      -- Add your custom command paths
      opts.formatters = opts.formatters or {}
      opts.formatters["tex-fmt"] = {
        command = "/home/marto/.cargo/bin/tex-fmt",
      }
    end,
  },
}
