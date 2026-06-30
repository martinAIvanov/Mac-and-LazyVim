-- ~/.config/nvim/lua/plugins/copilot-early.lua
return {
  {
    "zbirenbaum/copilot.lua",
    -- Make sure Copilot is loaded and configured BEFORE Avante runs
    lazy = false,
    priority = 1000,

    -- These opts are compatible with LazyVim's defaults; tweak if you want
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        -- if you use ai-cmp or blink.cmp, you might want hide_during_completion = true
      },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
        -- add or remove filetypes as you like
      },
    },

    config = function(_, opts)
      -- This is the crucial bit: actually set up Copilot
      require("copilot").setup(opts)
    end,
  },
}
