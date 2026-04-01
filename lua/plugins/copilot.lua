return {
  {
    "zbirenbaum/copilot.lua",
    opts = function(_, opts)
      opts.filetypes = opts.filetypes or {}

      -- Enable Copilot for everything by default
      opts.filetypes["*"] = true

      -- Disable it in Avante-related buffers
      opts.filetypes["avante"] = false
      opts.filetypes["Avante"] = false
      opts.filetypes["AvanteInput"] = false
    end,
  },
}
