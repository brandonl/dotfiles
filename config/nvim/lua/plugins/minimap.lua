return {
  {
    "nvim-mini/mini.map",
    version = false,
    config = function()
      local map = require("mini.map")
      map.setup({
        integrations = {
          map.gen_integration.builtin_search(),
          map.gen_integration.diagnostic({
            error = "DiagnosticSignError",
            warn = "DiagnosticSignWarn",
            info = "DiagnosticSignInfo",
            hint = "DiagnosticSignHint",
          }),
          map.gen_integration.gitsigns(),
        },
        window = {
          side = "right",
          width = 10,
          show_integration_count = false,
        },
      })

      local opened = false
      local function open_for_named_buffer(args)
        if opened then
          return
        end

        local buf = args.buf
        if vim.bo[buf].buftype ~= "" or vim.api.nvim_buf_get_name(buf) == "" then
          return
        end

        opened = true
        map.open()
      end

      vim.api.nvim_create_autocmd({ "BufEnter", "BufFilePost", "VimEnter" }, {
        callback = open_for_named_buffer,
        desc = "Open minimap for files",
      })

      vim.keymap.set("n", "<leader>uM", map.toggle, { desc = "Toggle minimap" })
    end,
  },
}
