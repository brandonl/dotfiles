local group = vim.api.nvim_create_augroup("KeepNeovimOpenAfterLastFile", { clear = true })

vim.api.nvim_create_autocmd("QuitPre", {
  group = group,
  callback = function()
    local buffer = vim.api.nvim_get_current_buf()
    if vim.fn.winnr("$") ~= 1 or vim.bo[buffer].buftype ~= "" or vim.api.nvim_buf_get_name(buffer) == "" then
      return
    end

    vim.cmd("Neotree filesystem show")
  end,
  desc = "Keep Neovim open at the project tree after closing the last file",
})
