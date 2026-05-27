return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      opts.init_options = opts.init_options or {}
      opts.init_options.settings = opts.init_options.settings or {}
      opts.settings = opts.settings or {}

      -- 1. Format Profile Connection (init_options)
      opts.init_options.settings.java = {
        format = {
          enabled = true,
          settings = {
            url = "file://" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:h") .. "/eclipse-formatter.xml",
            profile = "Default",
          },
        },
      }

      -- 2. Sort Logic Config Matrix (opts.settings)
      opts.settings.java = {
        sources = {
          organizeImports = {
            starThreshold = 3,
            staticStarThreshold = 3,
          },
        },
        completion = {
          importOrder = {
            "javax",
            "org",
            "com",
            "java.[a-z0-9_]+", -- Catches standard types (like java.io)

            -- FIX: By placing an empty string BEFORE the catch-all pattern,
            -- you force jdtls to create a clean visual blank line block.
            "",
            "java.util", -- Explicitly isolates the wildcard to the final block
          },
        },
      }
    end,
  },
}
