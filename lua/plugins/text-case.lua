return {
  {
    "johmsalas/text-case.nvim",
    -- Telescope dependency removed
    config = function()
      require("textcase").setup({})
    end,
    keys = {
      "ga", -- Keeps all default ga mappings (gaa, gas, etc.)
      -- New keymap that uses the native UI (which Snacks.nvim will pick up)
      { "ga.", "<cmd>TextCaseOpenOperator<CR>", mode = { "n", "x" }, desc = "Select Case (Snacks)" },
    },
    cmd = {
      "Subs",
      "TextCaseOpenOperator", -- Use this instead of TextCaseOpenTelescope
      "TextCaseStartReplacingCommand",
    },
    lazy = false,
  },
}
