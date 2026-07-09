-- ~/.config/nvim/lua/plugins/avante.lua

local DEFAULT_TIMEOUT_MS = 60000
local DEFAULT_TEMPERATURE = 0.2

-- AI Hub (OpenAI-compatible) endpoint
local AI_HUB_ENDPOINT = "https://adesso-ai-hub.3asabc.de/v1"

-- Warn if AI Hub key is missing
local function validate_aihub_key()
  if not os.getenv("SOVEREIGN_AI_API_KEY") then
    vim.notify(
      "Avante (AI Hub): SOVEREIGN_AI_API_KEY not set. Export your AI Hub API key in your shell.",
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

  local api_key = os.getenv("SOVEREIGN_AI_API_KEY")
  if not api_key or api_key == "" then
    vim.notify(
      "Avante (AI Hub): SOVEREIGN_AI_API_KEY not set. Cannot fetch models dynamically.",
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
          desc = m.description or m.desc or "",
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
    -- Minimal static fallback (you can extend this list if you want)
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
    api_key_name = "SOVEREIGN_AI_API_KEY",
    model = default_model,
    extra_request_body = global_extra,
  }
end

-- Small helper to convert model IDs into provider names
local function sanitize_model_id(id)
  -- replace anything that's not letter/number/underscore with "_"
  return (id:gsub("[^%w_]", "_"))
end

return {
  {
    "yetone/avante.nvim",
    version = false,
    build = "make",

    -- We override LazyVim's default config for Avante
    config = function(_, opts)
      validate_aihub_key()

      -- Keep and extend LazyVim's defaults
      opts.windows = opts.windows or {}
      opts.windows.input = vim.tbl_extend("force", opts.windows.input or {}, {
        height = 16,
      })

      opts.timeout = DEFAULT_TIMEOUT_MS
      opts.providers = opts.providers or {}

      ------------------------------------------------------------------
      -- 1) Copilot provider (inside Avante) – optional
      ------------------------------------------------------------------
      -- If this brings back the old error, comment this block out.
      opts.providers.copilot = vim.tbl_extend("force", opts.providers.copilot or {}, {
        timeout = 30000,
      })

      ------------------------------------------------------------------
      -- 2) AI Hub providers (one per model)
      ------------------------------------------------------------------
      for _, m in ipairs(AI_HUB_MODELS) do
        local provider_name = "aihub_" .. sanitize_model_id(m.id)

        opts.providers[provider_name] = create_aihub_provider(m.id, {
          temperature = DEFAULT_TEMPERATURE,
        })
      end

      ------------------------------------------------------------------
      -- 3) Default provider selection
      ------------------------------------------------------------------
      local default_model_id = "gpt-oss-120b-sovereign"
      local default_provider = "aihub_" .. sanitize_model_id(default_model_id)

      if not opts.providers[default_provider] then
        -- Fallback: first AI Hub model from the list
        local first = AI_HUB_MODELS[1]
        if first then
          default_provider = "aihub_" .. sanitize_model_id(first.id)
        end
      end

      -- If no provider is set, or it's still "copilot", prefer AI Hub
      if not opts.provider or opts.provider == "copilot" then
        opts.provider = default_provider
      end

      -- Make sure auto-suggestions don't force Copilot
      if opts.auto_suggestions_provider == "copilot" then
        opts.auto_suggestions_provider = opts.provider
      end

      ------------------------------------------------------------------
      -- 4) Finally run Avante setup with the enriched opts
      ------------------------------------------------------------------
      require("avante").setup(opts)
    end,
  },
}
