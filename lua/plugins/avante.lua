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
          desc = m.description or m.desc or "", -- simple description = id; you can add nicer labels later if you want
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

-- print("AI_HUB_MODELS: " .. vim.inspect(AI_HUB_MODELS))

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
    { "<leader>aa", false },
    { "<leader>at", false },
    {
      "<leader>av",
      "<cmd>AvanteToggle<CR>",
      desc = "Avante: Toggle Avante",
      mode = { "n", "v" },
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

    opts.timeout = DEFAULT_TIMEOUT_MS
    opts.providers = opts.providers or {}

    -- Copilot-Provider wie gehabt
    opts.providers.copilot = vim.tbl_extend("force", opts.providers.copilot or {}, {
      timeout = 30000,
    })

    -- Kleine Hilfsfunktion, um Model-IDs in Provider-Namen zu verwandeln
    local function sanitize_model_id(id)
      -- alles, was kein Buchstabe/Zahl/Unterstrich ist, durch "_" ersetzen
      return (id:gsub("[^%w_]", "_"))
    end

    -- Für jedes Modell aus AI_HUB_MODELS einen eigenen Provider anlegen
    for _, m in ipairs(AI_HUB_MODELS) do
      local provider_name = "aihub_" .. sanitize_model_id(m.id)

      opts.providers[provider_name] = create_aihub_provider(m.id, {
        temperature = DEFAULT_TEMPERATURE,
      })
    end

    -- Default-Provider beim Start:
    -- z.B. das souveräne GPT-OSS Modell, falls vorhanden
    local default_model_id = "gpt-oss-120b-sovereign"
    local default_provider = "aihub_" .. sanitize_model_id(default_model_id)

    if not opts.providers[default_provider] then
      -- Fallback: erstes Modell aus der Liste
      local first = AI_HUB_MODELS[1]
      default_provider = "aihub_" .. sanitize_model_id(first.id)
    end

    -- HIER: nur noch diesen Default setzen
    opts.provider = opts.provider or default_provider
  end,
}
