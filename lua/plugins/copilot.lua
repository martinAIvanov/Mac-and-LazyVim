return {
  {
    "zbirenbaum/copilot.lua",
    enabled = false,
    -- Crucial: DO NOT load on startup. Load only when you call the auth command
    cmd = "Copilot",
    event = "InsertEnter",
    priority = 1000,
    -- version = "v2.0.4",
    opts = {
      suggestion = { enabled = false }, -- Turn off to avoid conflicts with Avante/Blink
      panel = { enabled = false },
    },
    config = function(_, opts)
      require("copilot").setup(opts)
    end,
  },
}
