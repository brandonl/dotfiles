local group = vim.api.nvim_create_augroup("KeepNeovimOpenAfterLastFile", { clear = true })

local function is_file_buffer(buffer)
  return vim.bo[buffer].buftype == "" and vim.api.nvim_buf_get_name(buffer) ~= ""
end

vim.api.nvim_create_autocmd("QuitPre", {
  group = group,
  callback = function()
    local current_window = vim.api.nvim_get_current_win()
    local buffer = vim.api.nvim_get_current_buf()
    if not is_file_buffer(buffer) then
      return
    end

    local has_file_window = false
    local has_tree_window = false

    for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local window_buffer = vim.api.nvim_win_get_buf(window)
      if window ~= current_window and is_file_buffer(window_buffer) then
        has_file_window = true
      end
      if vim.bo[window_buffer].filetype == "neo-tree" then
        has_tree_window = true
      end
    end

    if not has_file_window and not has_tree_window then
      vim.cmd("Neotree filesystem show")
    end
  end,
  desc = "Keep Neovim open at the project tree after closing the last file",
})
