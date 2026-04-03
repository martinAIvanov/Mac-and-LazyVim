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

-- Dynamically fetch models from AI Hub /v1/models
local function fetch_aihub_models()
  local ok, curl = pcall(require, "plenary.curl")
  if not ok then
    vim.notify(
      "Avante (AI Hub): plenary.curl not available, using static model fallback.",
      vim.log.levels.WARN,
      { title = "Avante / AI Hub" }
    )
    return nil
  end

  local api_key = os.getenv("OPENAI_API_KEY")
  if not api_key or api_key == "" then
    vim.notify(
      "Avante (AI Hub): OPENAI_API_KEY not set. Cannot fetch models dynamically.",
      vim.log.levels.WARN,
      { title = "Avante / AI Hub" }
    )
    return nil
  end

  -- AI_HUB_ENDPOINT already ends with /v1, so /v1 + "/models" -> /v1/models
  local res = curl.get(AI_HUB_ENDPOINT .. "/models", {
    headers = {
      Authorization = "Bearer " .. api_key,
    },
  })

  if res.status ~= 200 then
    vim.notify(
      ("Avante (AI Hub): /models request failed (%s). Using static model fallback."):format(res.status),
      vim.log.levels.WARN,
      { title = "Avante / AI Hub" }
    )
    return nil
  end

  local ok_json, body = pcall(vim.json.decode, res.body)
  if not ok_json or type(body) ~= "table" or type(body.data) ~= "table" then
    vim.notify(
      "Avante (AI Hub): could not decode /models response. Using static model fallback.",
      vim.log.levels.WARN,
      { title = "Avante / AI Hub" }
    )
    return nil
  end

  local models = {}
  for _, m in ipairs(body.data) do
    if type(m.id) == "string" then
      -- Filter out pure embedding / embedding-like models if you don't want them in chat
      if not m.id:match("embedding") and not m.id:match("intfloat/e5") then
        table.insert(models, {
          id = m.id,
          desc = m.id, -- simple description = id; you can add nicer labels later if you want
        })
      end
    end
  end

  table.sort(models, function(a, b)
    return a.id < b.id
  end)

  if #models == 0 then
    vim.notify(
      "Avante (AI Hub): /models returned no usable models. Using static model fallback.",
      vim.log.levels.WARN,
      { title = "Avante / AI Hub" }
    )
    return nil
  end

  return models
end

-- All AI Hub chat models: dynamic fetch with static fallback
local AI_HUB_MODELS = fetch_aihub_models()
  or {
    -- Minimal static fallback (you can keep your full list here if you like)
    { id = "gpt-4o", desc = "gpt-4o" },
    { id = "gpt-4.1", desc = "gpt-4.1" },
    { id = "gpt-4.1-mini", desc = "gpt-4.1-mini" },
    { id = "gpt-4.1-nano", desc = "gpt-4.1-nano" },
  }

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

    -- Single AI Hub provider; default model = first in AI_HUB_MODELS
    local default_aihub_model = AI_HUB_MODELS[1].id
    opts.providers.aihub = create_aihub_provider(default_aihub_model, global_extra)
  end,
}
