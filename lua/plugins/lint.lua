return {
  "mfussenegger/nvim-lint",
  opts = {
    linters_by_ft = {
      java = { "checkstyle" },
    },
    linters = {
      checkstyle = {
        args = {
          "-c",
          vim.fn.expand("~/.config/checkstyle/checkstyle.xml"),
          "-f",
          "plain",
        },
        -- This parser ignores the "Starting audit" lines and reads the [ERROR] lines
        parser = require("lint.parser").from_errorformat(
          "[ERROR] %f:%l:%c: %m [%*[^]]]",
          { source = "checkstyle", severity = vim.diagnostic.severity.WARN }
        ),
      },
    },
  },
}
