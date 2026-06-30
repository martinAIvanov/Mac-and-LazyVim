-- ~/.config/nvim/lua/plugins/avante-no-copilot.lua
return {
  {
    "yetone/avante.nvim",

    -- This overrides LazyVim's default config for Avante
    config = function(_, opts)
      -- Ensure providers table exists
      opts.providers = opts.providers or {}

      -- 1) Completely remove the Copilot provider from Avante
      opts.providers.copilot = nil

      -- 2) Make sure Copilot is not selected as the default provider
      if opts.provider == "copilot" then
        -- fall back to any other provider LazyVim configured (e.g. "openai")
        opts.provider = "openai"
      end

      -- 3) Make sure auto_suggestions are not tied to Copilot
      if opts.auto_suggestions_provider == "copilot" then
        opts.auto_suggestions_provider = opts.provider
      end

      -- 4) Finally run Avante's setup with the sanitized opts
      require("avante").setup(opts)
    end,
  },
}
