return {
  {
    "vuki656/package-info.nvim",
    lazy = false,
    -- Whether to autostart when `package.json` is opened
    opts = { autostart = true },
    keys = {
      {
        "<leader>vs",
        function()
          require("package-info").show()
        end,
        noremap = true,
        silent = true,
        desc = "Show versions",
      },
      {
        "<leader>vc",
        function()
          require("package-info").hide()
        end,
        noremap = true,
        silent = true,
        desc = "Hide versions",
      },
      {
        "<leader>vt",
        function()
          require("package-info").toggle()
        end,
        noremap = true,
        silent = true,
        desc = "Toggle versions visibility",
      },
      {
        "<leader>vu",
        function()
          require("package-info").update()
        end,
        noremap = true,
        silent = true,
        desc = "Update package",
      },
      {
        "<leader>vd",
        function()
          require("package-info").delete()
        end,
        noremap = true,
        silent = true,
        desc = "Delete package",
      },
      {
        "<leader>vi",
        function()
          require("package-info").install()
        end,
        noremap = true,
        silent = true,
        desc = "Install package",
      },
      {
        "<leader>vp",
        function()
          require("package-info").change_version()
        end,
        noremap = true,
        silent = true,
        desc = "Change version",
      },
    },
  },
}
