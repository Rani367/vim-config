-- Minimal Neovim config: file tree, terminal, run current file
-- Keymaps: <Space>e = file tree, <Space>t = floating terminal, <Space>r = run file

-- Set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

--------------------------------------------------------------------------------
-- Bootstrap lazy.nvim
--------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

--------------------------------------------------------------------------------
-- Plugins
--------------------------------------------------------------------------------
require("lazy").setup({
  -- File tree
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- Disable netrw
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      require("nvim-tree").setup({
        view = {
          side = "left",
          width = 30,
        },
        filters = {
          dotfiles = true,       -- Hide dotfiles by default
          git_ignored = true,    -- Hide gitignored files by default
        },
        git = {
          enable = true,         -- Show git status
        },
        renderer = {
          icons = {
            show = {
              git = true,
            },
          },
        },
      })
    end,
  },

  -- Terminal
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = function(term)
          if term.direction == "horizontal" then
            return 15
          elseif term.direction == "float" then
            return 20
          end
        end,
        shade_terminals = false,
        float_opts = {
          border = "curved",
          width = function() return math.floor(vim.o.columns * 0.8) end,
          height = function() return math.floor(vim.o.lines * 0.8) end,
        },
      })
    end,
  },
}, {
  -- Lazy.nvim options: keep UI minimal
  ui = { border = "rounded" },
  change_detection = { notify = false },
})

--------------------------------------------------------------------------------
-- Terminal functions
--------------------------------------------------------------------------------
local Terminal = require("toggleterm.terminal").Terminal

-- Floating terminal (singleton)
local floating_term = Terminal:new({
  direction = "float",
  hidden = true,
})

function _G.toggle_floating_terminal()
  floating_term:toggle()
end

-- Bottom terminal for running files (singleton)
local run_term = Terminal:new({
  direction = "horizontal",
  hidden = true,
  close_on_exit = false,
})

function _G.run_current_file_in_bottom_terminal()
  local file = vim.fn.expand("%:p")  -- Absolute path
  local ft = vim.bo.filetype
  local cmd

  if ft == "python" then
    cmd = "python3 " .. vim.fn.shellescape(file)
  elseif ft == "javascript" or ft == "typescript" then
    cmd = "node " .. vim.fn.shellescape(file)
  elseif ft == "sh" or ft == "bash" or ft == "zsh" then
    cmd = vim.fn.shellescape(file)
  else
    -- Fallback: try to execute directly
    cmd = vim.fn.shellescape(file)
  end

  -- Open terminal, clear it, and run command
  run_term:open()
  run_term:send("clear && " .. cmd, true)
end

--------------------------------------------------------------------------------
-- Keymaps
--------------------------------------------------------------------------------
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- <Space>e → Toggle file tree
map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", opts)

-- <Space>t → Toggle floating terminal
map("n", "<leader>t", "<cmd>lua toggle_floating_terminal()<cr>", opts)

-- <Space>r → Run current file in bottom terminal
map("n", "<leader>r", "<cmd>lua run_current_file_in_bottom_terminal()<cr>", opts)

-- <Esc> in terminal mode returns to normal mode
map("t", "<Esc>", "<C-\\><C-n>", opts)
