return {
  {
    "Isrothy/neominimap.nvim",
    version = "v3.16.0",
    lazy = false,
    init = function()
      vim.g.neominimap = {
        auto_enable = true,
        layout = "split",
        split = {
          minimap_width = 10,
          fix_width = true,
          direction = "right",
          persist = true,
        },
        search = {
          enabled = true,
          mode = "line",
        },
      }
    end,
    keys = {
      { "<leader>uM", "<cmd>Neominimap Toggle<cr>", desc = "Toggle minimap" },
    },
  },
}
