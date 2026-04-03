-- Basic settings
local DEFAULT_TIMEOUT_MS = 60000
local DEFAULT_TEMPERATURE = 0.2
local MAX_TOKENS = 20480

-- AI Hub (OpenAI-compatible) endpoint
local AI_HUB_ENDPOINT = "https://api.ai-hub.adesso.de/v1"

-- List of AI Hub chat models you can access.
-- NOTE: I *exclude* pure embedding models (like text-embedding-3-large,
-- intfloat/e5-mistral-7b-instruct) because Avante's chat endpoint
-- would fail with them.
local PROVIDER_CONFIGS = {
  -- GPT family
  {
    name = "aihub-gpt-4o",
    model = "gpt-4o",
    desc = "GPT-4o (general coding & chat)",
  },
  {
    name = "aihub-gpt-4.1",
    model = "gpt-4.1",
    desc = "GPT-4.1 (strong generalist)",
  },
  {
    name = "aihub-gpt-4.1-mini",
    model = "gpt-4.1-mini",
    desc = "GPT-4.1 Mini (fast & cheap)",
  },
  {
    name = "aihub-gpt-4.1-nano",
    model = "gpt-4.1-nano",
    desc = "GPT-4.1 Nano (very fast, lightweight)",
  },
  {
    name = "aihub-gpt-5-nano",
    model = "gpt-5-nano",
    desc = "GPT-5 Nano (small, experimental)",
  },
  {
    name = "aihub-gpt-5-mini",
    model = "gpt-5-mini",
    desc = "GPT-5 Mini (fast, experimental)",
  },
  {
    name = "aihub-gpt-5.1",
    model = "gpt-5.1",
    desc = "GPT-5.1 (advanced generalist)",
  },
  {
    name = "aihub-gpt-5",
    model = "gpt-5",
    desc = "GPT-5 (flagship, if available)",
  },

  -- US-prefixed GPT / Gemini models
  {
    name = "aihub-us-gpt-5.4",
    model = "US-gpt-5.4",
    desc = "US GPT-5.4 (US region)",
  },
  {
    name = "aihub-us-gpt-5.3-codex",
    model = "US-gpt-5.3-codex",
    desc = "US GPT-5.3 Codex (code-focused, US region)",
  },
  {
    name = "aihub-us-gemini-3-flash-preview",
    model = "US-gemini-3-flash-preview",
    desc = "US Gemini 3 Flash Preview (fast, US region)",
  },
  {
    name = "aihub-us-gemini-3.1-pro-preview",
    model = "US-gemini-3.1-pro-preview",
    desc = "US Gemini 3.1 Pro Preview (strong, US region)",
  },

  -- Gemini 2.5
  {
    name = "aihub-gemini-2.5-flash",
    model = "gemini-2.5-flash",
    desc = "Gemini 2.5 Flash (fast, cheap)",
  },
  {
    name = "aihub-gemini-2.5-pro",
    model = "gemini-2.5-pro",
    desc = "Gemini 2.5 Pro (strong generalist)",
  },

  -- Claude family (4.5 / 4.6)
  {
    name = "aihub-claude-sonnet-4.6",
    model = "claude-sonnet-4-6",
    desc = "Claude Sonnet 4.6 (balanced, generalist)",
  },
  {
    name = "aihub-claude-opus-4.6",
    model = "claude-opus-4-6",
    desc = "Claude Opus 4.6 (heavy reasoning, expensive)",
  },
  {
    name = "aihub-claude-sonnet-4.5",
    model = "claude-sonnet-4-5",
    desc = "Claude Sonnet 4.5 (strong coding & reasoning)",
  },
  {
    name = "aihub-claude-opus-4.5",
    model = "claude-opus-4-5",
    desc = "Claude Opus 4.5 (very strong reasoning, pricey)",
  },
  {
    name = "aihub-claude-haiku-4.5",
    model = "claude-haiku-4.5",
    desc = "Claude Haiku 4.5 (fast, lightweight Claude)",
  },

  -- LLaMA / Gemma / Qwen etc.
  {
    name = "aihub-llama-3.3-70b",
    model = "llama-3-3-70b",
    desc = "Llama 3.3 70B (meta open model)",
  },
  {
    name = "aihub-gemma-3-27b-it",
    model = "google/gemma-3-27b-it",
    desc = "Gemma 3 27B (instruction-tuned)",
  },
  {
    name = "aihub-qwen3-235b",
    model = "qwen3-235b",
    desc = "Qwen3 235B (large generalist)",
  },
  {
    name = "aihub-qwen3-3.5-122b-sovereign",
    model = "qwen-3.5-122b-sovereign",
    desc = "Qwen 3.5 122B Sovereign (sovereign-hosted)",
  },
  {
    name = "aihub-qwen3-coder-480b",
    model = "qwen3-coder-480b",
    desc = "Qwen3 Coder 480B (code-focused)",
  },
  {
    name = "aihub-gpt-oss-120b-sovereign",
    model = "gpt-oss-120b-sovereign",
    desc = "GPT-OSS 120B (sovereign model)",
  },
  {
    name = "aihub-devstral-2-123b",
    model = "devstral-2-123b",
    desc = "Devstral 2 123B (big open model)",
  },

  -- OpenAI o- / o3 reasoning models
  {
    name = "aihub-o3-mini",
    model = "o3-mini",
    desc = "o3-mini (reasoning-focused, compact)",
  },
  {
    name = "aihub-o4-mini",
    model = "o4-mini",
    desc = "o4-mini (stronger reasoning, compact)",
  },
}

-- Validate API key (AI Hub uses OPENAI_API_KEY here)
local function validate_api_key()
  if not os.getenv("OPENAI_API_KEY") then
    vim.notify(
      "Avante (AI Hub): OPENAI_API_KEY not set. Export your AI Hub API key in your shell.",
      vim.log.levels.WARN,
      { title = "Avante / AI Hub" }
    )
  end
end

-- Create an AI Hub provider configuration (OpenAI-compatible)
local function create_aihub_provider(model, extra, global_extra)
  local provider = {
    __inherited_from = "openai",
    endpoint = AI_HUB_ENDPOINT,
    api_key_name = "OPENAI_API_KEY",
    model = model,
  }

  provider.extra_request_body = vim.tbl_extend("force", vim.deepcopy(global_extra), extra or {})
  return provider
end

-- Picker to switch between:
-- - Copilot
-- - All AI Hub “providers” (one per model above)
local function switch_provider()
  local avante_config = require("avante.config")
  local snacks = require("snacks")

  local current = avante_config.provider
  local items = {}

  -- First entry: Copilot
  do
    local indicator = (current == "copilot") and "● " or "  "
    local preview_lines = {
      "# copilot",
      "",
      "**Description:** GitHub Copilot (local agent)",
      "",
      "**Use Case:**",
      "• Inline coding help",
      "• Tight IDE integration",
      "",
    }

    table.insert(items, {
      text = string.format("%s%-30s %s", indicator, "copilot", "GitHub Copilot"),
      provider = "copilot",
      preview = {
        text = table.concat(preview_lines, "\n"),
        ft = "markdown",
      },
    })
  end

  -- Then: all AI Hub models
  for _, p in ipairs(PROVIDER_CONFIGS) do
    local indicator = (p.name == current) and "● " or "  "

    local preview_lines = {
      "# " .. p.name,
      "",
      "**Description:** " .. (p.desc or ""),
      "",
    }

    if p.model and p.model ~= "" then
      table.insert(preview_lines, "**Model:** `" .. p.model .. "`")
      table.insert(preview_lines, "")
    end

    table.insert(preview_lines, "---")
    table.insert(preview_lines, "")
    table.insert(preview_lines, "**Backend:** adesso AI Hub (OpenAI-compatible API)")

    table.insert(items, {
      text = string.format("%s%-30s %s", indicator, p.name, p.desc or ""),
      provider = p.name,
      model = p.model,
      preview = {
        text = table.concat(preview_lines, "\n"),
        ft = "markdown",
      },
    })
  end

  snacks.picker({
    items = items,
    prompt = "Select Avante Provider (Copilot / AI Hub)",
    format = "text",
    preview = "preview",
    layout = {
      preset = "default",
    },
    confirm = function(picker, item)
      picker:close()
      if item then
        avante_config.provider = item.provider
        vim.notify(("Avante: switched provider to %s"):format(item.provider), vim.log.levels.INFO, { title = "Avante" })
      end
    end,
  })
end

return {
  "yetone/avante.nvim",
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  -- ⚠️ must add this setting! ! !
  build = vim.fn.has("win32") ~= 0 and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
    or "make",
  event = "VeryLazy",
  version = false, -- Never set this value to "*"! Never!

  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    "folke/snacks.nvim", -- for input provider snacks
    "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    {
      "zbirenbaum/copilot.lua", -- for providers='copilot'
      cmd = "Copilot",
      event = "InsertEnter",
      opts = {
        suggestion = {
          enabled = true,
          auto_trigger = true,
        },
        panel = { enabled = false },
        should_attach = function(bufnr)
          return true
        end,
      },
    },
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
  -- Override default <leader>am to use our multi-provider picker
  keys = {
    {
      "<leader>ap",
      switch_provider,
      desc = "Avante: Switch Provider (Copilot / AI Hub models)",
    },
  },

  config = function(_, opts)
    validate_api_key()
    require("avante").setup(opts)
  end,

  opts = function(_, opts)
    opts.windows = opts.windows or {}
    opts.windows.input = vim.tbl_extend("force", opts.windows.input or {}, {
      height = 16,
    })

    -- Default provider when Avante starts:
    -- "copilot"  -> GitHub Copilot backend
    -- or e.g. "aihub-gpt-4o" to default to AI Hub GPT-4o
    opts.provider = "copilot"

    opts.timeout = DEFAULT_TIMEOUT_MS

    -- Global defaults for all AI Hub models
    local global_extra = {
      temperature = DEFAULT_TEMPERATURE,
      max_tokens = MAX_TOKENS,
    }

    opts.extra_request_body = global_extra
    opts.providers = opts.providers or {}

    -- Register all AI Hub models as separate providers
    for _, cfg in ipairs(PROVIDER_CONFIGS) do
      opts.providers[cfg.name] = create_aihub_provider(cfg.model, cfg.extra, global_extra)
    end

    -- We don’t touch the built-in "copilot" provider – it stays available.
  end,
}
