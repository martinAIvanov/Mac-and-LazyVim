return {
  "mfussenegger/nvim-dap",
  opts = function(_, opts)
    local dap = require("dap")

    if dap.listeners.before.event_exited then
      dap.listeners.before.event_exited["dapui_config"] = nil
    end

    if dap.listeners.before.event_terminated then
      dap.listeners.before.event_terminated["dapui_config"] = nil
    end

    return opts
  end,
}
