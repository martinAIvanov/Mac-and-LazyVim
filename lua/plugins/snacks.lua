return {
  {
    "folke/snacks.nvim",
    opts = {
      -- Fixes "setup {disabled}" warnings
      statuscolumn = { enabled = true },
      image = {
        enabled = true,
        doc = {
          inline = false,
          float = true,

          -- Values are terminal cells, not pixels.
          max_width = 175,
          max_height = 45,
        },
        -- Mermaid-specific rendering settings
        convert = {
          notify = true,
          mermaid = function()
            local theme = vim.o.background == "light" and "neutral" or "dark"

            return {
              "-i",
              "{src}",
              "-o",
              "{file}",
              "-b",
              "transparent",
              "-t",
              theme,

              -- Use your Mermaid configuration file.
              "-c",
              vim.fn.expand("~/.config/nvim/mermaid-large.json"),
              -- Render at higher pixel density for a sharper diagram.
              "-s",
              "8",
            }
          end,
        },
      },
      styles = {
        snacks_image = {
          -- Position relative to the whole Neovim screen, not the cursor.
          relative = "editor",
          row = 1,
          col = 3,

          border = true,
          focusable = false,
          backdrop = false,
        },
      },
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
