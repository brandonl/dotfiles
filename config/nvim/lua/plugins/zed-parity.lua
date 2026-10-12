return {
  {
    "mechatroner/rainbow_csv",
  },
  {
    "nvim-mini/mini.icons",
    dependencies = {
      { "catppuccin/nvim", name = "catppuccin" },
    },
    opts = {
      style = "glyph",
    },
    config = function(_, opts)
      require("mini.icons").setup(opts)

      local palette = require("catppuccin.palettes").get_palette("macchiato")
      local icon_colors = {
        MiniIconsAzure = palette.sapphire,
        MiniIconsBlue = palette.blue,
        MiniIconsCyan = palette.sky,
        MiniIconsGreen = palette.green,
        MiniIconsGrey = palette.overlay2,
        MiniIconsOrange = palette.peach,
        MiniIconsPurple = palette.mauve,
        MiniIconsRed = palette.red,
        MiniIconsYellow = palette.yellow,
      }

      local function apply_icon_colors()
        for group, color in pairs(icon_colors) do
          vim.api.nvim_set_hl(0, group, { fg = color })
        end
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("MiniIconsCatppuccinMacchiato", { clear = true }),
        callback = apply_icon_colors,
      })
      apply_icon_colors()
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      linehl = true,
      numhl = true,
      word_diff = true,
      current_line_blame = true,
      current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
      },
    },
  },
}
