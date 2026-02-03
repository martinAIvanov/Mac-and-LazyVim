return {
  {
    "folke/snacks.nvim",
    opts = {
      -- Fixes "setup {disabled}" warnings
      statuscolumn = { enabled = true },
      image = { enabled = true }, -- Requires ImageMagick to be installed on OpenBSD
      scroll = { enabled = true },
      words = { enabled = true },
      -- Fixes "vim.ui.input is not set"
      input = { enabled = true },
      -- Fixes "vim.ui.select for Snacks.picker is not enabled"
      picker = {
        enabled = true,
        ui_select = true, -- This specifically hooks into vim.ui.select
      },
    },
  },
}
