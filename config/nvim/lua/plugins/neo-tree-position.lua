local function place_tree_on_right(winid)
  if not vim.api.nvim_win_is_valid(winid) then
    return
  end

  vim.api.nvim_win_call(winid, function()
    vim.cmd("wincmd L")
    pcall(vim.api.nvim_win_set_width, winid, 40)
  end)
end

local function schedule_tree_on_right(winid)
  vim.schedule(function()
    place_tree_on_right(winid)
  end)
end

local function open_clicked_node(state)
  local mouse = vim.fn.getmousepos()
  if mouse.winid == state.winid and mouse.line > 0 then
    vim.api.nvim_win_set_cursor(state.winid, { mouse.line, 0 })
  end
  state.commands.open(state)
end

vim.keymap.set({ "n", "i" }, "<LeftMouse>", function()
  local mouse = vim.fn.getmousepos()
  if mouse.winid > 0 and vim.api.nvim_win_is_valid(mouse.winid) then
    local bufnr = vim.api.nvim_win_get_buf(mouse.winid)
    if vim.bo[bufnr].filetype == "neo-tree" then
      local manager = require("neo-tree.sources.manager")
      local state = manager.get_state_for_window(mouse.winid)
      if state then
        if vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
          vim.cmd("stopinsert")
        end
        vim.api.nvim_set_current_win(mouse.winid)
        open_clicked_node(state)
        return
      end
    end
  end

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<LeftMouse>", true, false, true), "n", false)
end, { desc = "Open Neo-tree nodes with a single click" })

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      close_if_last_window = false,
      open_files_in_last_window = false,
      open_files_do_not_replace_types = { "terminal", "Trouble", "qf", "edgy", "neominimap" },
      window = {
        position = "right",
        width = 40,
      },
      event_handlers = {
        {
          event = "neo_tree_window_after_open",
          handler = function(args)
            if args.position == "right" then
              schedule_tree_on_right(args.winid)
            end
          end,
        },
        {
          event = "file_opened",
          handler = function(file_path)
            vim.schedule(function()
              local path = vim.fn.fnamemodify(file_path, ":p")
              local file_winids = {}
              local minimap_winid
              local tree_winid

              for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                local bufnr = vim.api.nvim_win_get_buf(winid)
                local name = vim.api.nvim_buf_get_name(bufnr)
                if vim.bo[bufnr].filetype == "neo-tree" then
                  tree_winid = winid
                elseif vim.bo[bufnr].filetype == "neominimap" then
                  minimap_winid = winid
                elseif vim.bo[bufnr].buftype == "" and vim.fn.fnamemodify(name, ":p") == path then
                  file_winids[#file_winids + 1] = winid
                end
              end

              if #file_winids ~= 1 or not tree_winid then
                return
              end

              local file_winid = file_winids[1]
              local minimap_col = minimap_winid and vim.api.nvim_win_get_position(minimap_winid)[2]
              local file_col = vim.api.nvim_win_get_position(file_winid)[2]
              if minimap_col and minimap_col < file_col then
                vim.api.nvim_win_call(file_winid, function()
                  vim.cmd("wincmd H")
                end)
              end
              place_tree_on_right(tree_winid)
            end)
          end,
        },
      },
      filesystem = {
        window = {
          mappings = {
            ["<LeftMouse>"] = open_clicked_node,
            ["<2-LeftMouse>"] = "noop",
          },
        },
      },
    },
  },
}
