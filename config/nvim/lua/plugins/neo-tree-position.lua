return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      window = {
        position = "right",
      },
      filesystem = {
        window = {
          mappings = {
            ["<LeftMouse>"] = "open",
          },
        },
      },
    },
  },
}
