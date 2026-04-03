-- Avante + adesso AI Hub + Copilot (macOS)
--
-- Usage:
--   <leader>am -> Avante's default model/provider picker (great for Copilot)
--   <leader>aH -> AI Hub model picker (only AI Hub models)
--
-- To use AI Hub in Avante, select provider "aihub" via <leader>am.
-- Then use <leader>aH to switch the underlying AI Hub model.

local DEFAULT_TIMEOUT_MS = 60000
local DEFAULT_TEMPERATURE = 0.2

-- AI Hub (OpenAI-compatible) endpoint
local AI_HUB_ENDPOINT = "https://adesso-ai-hub.3asabc.de/v1"

-- All AI Hub chat models you can use (excluding pure embedding models)
local AI_HUB_MODELS = {
  -- GPT family
  { id = "gpt-4o", desc = "GPT-4o (general coding & chat)" },
  { id = "gpt-4.1", desc = "GPT-4.1 (strong generalist)" },
  { id = "gpt-4.1-mini", desc = "GPT-4.1 Mini (fast & cheap)" },
  { id = "gpt-4.1-nano", desc = "GPT-4.1 Nano (very fast, lightweight)" },
  { id = "gpt-5-nano", desc = "GPT-5 Nano (small, experimental)" },
  { id = "gpt-5-mini", desc = "GPT-5 Mini (fast, experimental)" },
  { id = "gpt-5.1", desc = "GPT-5.1 (advanced generalist)" },
  { id = "gpt-5", desc = "GPT-5 (flagship, if available)" },

  -- US-prefixed GPT / Gemini models
  { id = "US-gpt-5.4", desc = "US GPT-5.4 (US region)" },
  { id = "US-gpt-5.3-codex", desc = "US GPT-5.3 Codex (code-focused, US region)" },
  { id = "US-gemini-3-flash-preview", desc = "US Gemini 3 Flash Preview (fast, US region)" },
  { id = "US-gemini-3.1-pro-preview", desc = "US Gemini 3.1 Pro Preview (strong, US region)" },

  -- Gemini 2.5
  { id = "gemini-2.5-flash", desc = "Gemini 2.5 Flash (fast, cheap)" },
  { id = "gemini-2.5-pro", desc = "Gemini 2.5 Pro (strong generalist)" },

  -- Claude family (4.5 / 4.6)
  { id = "claude-sonnet-4-6", desc = "Claude Sonnet 4.6 (balanced, generalist)" },
  { id = "claude-opus-4-6", desc = "Claude Opus 4.6 (heavy reasoning, expensive)" },
  { id = "claude-sonnet-4-5", desc = "Claude Sonnet 4.5 (strong coding & reasoning)" },
  { id = "claude-opus-4-5", desc = "Claude Opus 4.5 (very strong reasoning, pricey)" },
  { id = "claude-haiku-4.5", desc = "Claude Haiku 4.5 (fast, lightweight Claude)" },

  -- LLaMA / Gemma / Qwen etc.
  { id = "llama-3-3-70b", desc = "Llama 3.3 70B (Meta open model)" },
  { id = "google/gemma-3-27b-it", desc = "Gemma 3 27B (instruction-tuned)" },
  { id = "qwen3-235b", desc = "Qwen3 235B (large generalist)" },
  { id = "qwen-3.5-122b-sovereign", desc = "Qwen 3.5 122B Sovereign (sovereign-hosted)" },
  { id = "qwen3-coder-480b", desc = "Qwen3 Coder 480B (code-focused)" },
  { id = "gpt-oss-120b-sovereign", desc = "GPT-OSS 120B (sovereign model)" },
  { id = "devstral-2-123b", desc = "Devstral 2 123B (big open model)" },

  -- OpenAI o- / o3 reasoning models
  { id = "o3-mini", desc = "o3-mini (reasoning-focused, compact)" },
  { id = "o4-mini", desc = "o4-mini (stronger reasoning, compact)" },
}

-- Warn if AI Hub key is missing
local function validate_aihub_key()
  if not os.getenv("OPENAI_API_KEY") then
    vim.notify(
      "Avante (AI Hub): OPENAI_API_KEY not set. Export your AI Hub API key in your shell.",
      vim.log.levels.WARN,
      { title = "Avante / AI Hub" }
    )
  end
end

-- Single AI Hub provider (OpenAI-compatible)
local function create_aihub_provider(default_model, global_extra)
  return {
    __inherited_from = "openai",
    endpoint = AI_HUB_ENDPOINT,
    api_key_name = "OPENAI_API_KEY",
    model = default_model,
    extra_request_body = global_extra,
  }
end

-- Picker: switch AI Hub model (only affects provider="aihub")
local function switch_aihub_model()
  local avante_config = require("avante.config")
  local snacks = require("snacks")

  local current_model = ((avante_config.providers or {}).aihub or {}).model or AI_HUB_MODELS[1].id

  local items = {}
  for _, m in ipairs(AI_HUB_MODELS) do
    local indicator = (m.id == current_model) and "● " or "  "

    local preview_lines = {
      "# " .. m.id,
      "",
      "**Model:** `" .. m.id .. "`",
      "",
      "**Description:** " .. (m.desc or ""),
      "",
      "---",
      "",
      "**Backend:** adesso AI Hub (OpenAI-compatible API)",
    }

    table.insert(items, {
      text = string.format("%s%-28s %s", indicator, m.id, m.desc or ""),
      model = m.id,
      preview = {
        text = table.concat(preview_lines, "\n"),
        ft = "markdown",
      },
    })
  end

  snacks.picker({
    items = items,
    prompt = "Select AI Hub model",
    format = "text",
    preview = "preview",
    layout = { preset = "default" },
    confirm = function(picker, item)
      picker:close()
      if item then
        avante_config.providers = avante_config.providers or {}
        avante_config.providers.aihub = avante_config.providers.aihub or {}
        avante_config.providers.aihub.model = item.model
        vim.notify(
          ("Avante: AI Hub model set to %s"):format(item.model),
          vim.log.levels.INFO,
          { title = "Avante / AI Hub" }
        )
      end
    end,
  })
end

return {
  "yetone/avante.nvim",

  build = vim.fn.has("win32") ~= 0 and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
    or "make",
  event = "VeryLazy",
  version = false,

  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "folke/snacks.nvim", -- used by AI Hub model picker
    "nvim-tree/nvim-web-devicons",

    {
      "zbirenbaum/copilot.lua",
      cmd = "Copilot",
      event = "InsertEnter",
      opts = {
        suggestion = {
          enabled = true,
          auto_trigger = true,
        },
        panel = { enabled = false },
        should_attach = function(_)
          return true
        end,
      },
    },

    {
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = { insert_mode = true },
          use_absolute_path = true,
        },
      },
    },
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },

  -- We DO NOT touch <leader>am.
  -- We only add <leader>aH for AI Hub model selection.
  keys = {
    {
      "<leader>aH",
      switch_aihub_model,
      desc = "Avante: Switch AI Hub model",
    },
  },

  config = function(_, opts)
    validate_aihub_key()
    require("avante").setup(opts)
  end,

  opts = function(_, opts)
    opts.windows = opts.windows or {}
    opts.windows.input = vim.tbl_extend("force", opts.windows.input or {}, {
      height = 16,
    })

    -- Default provider when Avante starts:
    -- "copilot" -> Copilot backend (and Avante's <leader>am for Copilot models)
    -- "aihub"   -> AI Hub backend with default model (below)
    opts.provider = opts.provider or "copilot"

    opts.timeout = DEFAULT_TIMEOUT_MS

    -- Global defaults for AI Hub
    local global_extra = {
      temperature = DEFAULT_TEMPERATURE,
    }

    opts.extra_request_body = global_extra
    opts.providers = opts.providers or {}

    -- Ensure Copilot provider exists (Avante will augment it)
    opts.providers.copilot = vim.tbl_extend("force", opts.providers.copilot or {}, {
      timeout = 30000,
    })

    -- Single AI Hub provider; default model = first in AI_HUB_MODELS (currently gpt-4o)
    local default_aihub_model = AI_HUB_MODELS[1].id
    opts.providers.aihub = create_aihub_provider(default_aihub_model, global_extra)
  end,
}
