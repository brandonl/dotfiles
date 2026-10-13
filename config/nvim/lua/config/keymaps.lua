local function scroll_at_mouse(direction)
  local mouse = vim.fn.getmousepos()
  local win = mouse.winid
  if win <= 0 or not vim.api.nvim_win_is_valid(win) then
    win = vim.api.nvim_get_current_win()
  end

  local buf = vim.api.nvim_win_get_buf(win)
  local amount = tonumber(vim.o.mousescroll:match("ver:(%d+)")) or 3

  vim.api.nvim_win_call(win, function()
    if vim.bo[buf].buftype ~= "" or vim.wo[win].diff then
      local key = direction > 0 and "\5" or "\25"
      vim.cmd.normal({ args = { tostring(amount) .. key }, bang = true })
      return
    end

    local view = vim.fn.winsaveview()
    local height = vim.api.nvim_win_get_height(win)
    local last_line = vim.api.nvim_buf_line_count(buf)
    local visible_rows = math.max(1, math.ceil(height * 3 / 4))
    local max_topline = math.max(1, last_line - visible_rows + 1)
    view.topline = math.max(1, math.min(max_topline, view.topline + direction * amount))
    vim.fn.winrestview(view)
  end)
end

vim.keymap.set({ "n", "i", "v" }, "<ScrollWheelDown>", function()
  scroll_at_mouse(1)
end, { desc = "Scroll down without overscrolling EOF" })

vim.keymap.set({ "n", "i", "v" }, "<ScrollWheelUp>", function()
  scroll_at_mouse(-1)
end, { desc = "Scroll up" })
