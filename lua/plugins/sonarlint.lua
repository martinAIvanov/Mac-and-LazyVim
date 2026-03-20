return {
  "https://gitlab.com/schrieveslaach/sonarlint.nvim",
  name = "sonarlint",
  dependencies = {
    "neovim/nvim-lspconfig",
    "mason-org/mason.nvim",
    "mason-org/mason-lspconfig.nvim",
    "nvim-lua/plenary.nvim",
    "lewis6991/gitsigns.nvim", -- recommended for Connected Mode / SCM info
  },
  ft = { "typescript", "typescriptreact", "javascript", "javascriptreact", "html", "css", "scss", "java" },
  config = function()
    -- Make sure mason is initialized somewhere in your setup:
    -- require("mason").setup()
    -- require("mason-lspconfig").setup()

    require("sonarlint").setup({
      server = {
        cmd = {
          "sonarlint-language-server",
          "-stdio",
          "-analyzers",
          -- Adjust the list of analyzers you actually have installed via mason.
          -- These are commonly available jars; keep or remove as needed.
          vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarjs.jar"), -- JS/TS rules
          vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarhtml.jar"), -- JSX/HTML rules
          vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarcss.jar"), -- CSS-in-JS, style files, etc.
          vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarjava.jar"),
        },
        settings = {
          sonarlint = {
            pathToNode = "/Users/martin.ivanov/.nvm/versions/node/v22.13.0/bin/node",
            -- javascript = { node = { maxspace = 8192 } }, -- Increase heap for Angular/large files
            -- Optional example settings; tweak to your needs
            -- rules = {
            -- Example: disable a rule
            -- rule_suppression = {
            --   rules = { "javascript:S1192" },
            -- },

            -- Connected mode example stub (fill with your real values if you use it):
            -- connection = {
            --   server = {
            --     url = "https://sonarqube.example.com",
            --     organization = "my-org",
            --     token = "YOUR_TOKEN_HERE",
            --   },
            -- },
            -- ["javascript:S1192"] = { level = "on" }, -- Explicitly enable
            -- ["typescript:S3776"] = { level = "on" },
            -- ["typescript:S6477"] = { level = "on" }, -- React rules often follow this S-series
            -- ["typescript:S6480"] = { level = "on" },
            -- Add more as needed
            -- },
          },
        },
      },

      -- filetypes that should be analyzed by sonarlint
      filetypes = {
        "typescript",
        "typescriptreact", -- .tsx
        "javascript",
        "javascriptreact", -- .jsx
        "html",
        "css",
        "scss",
        "java",
      },
    })
  end,
}
