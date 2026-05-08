-- 1. THE KILL SWITCH (Must be at the very top)
-- This stubs out the failing Treesitter function so the system runtime can't crash Neovim.
pcall(function()
  vim.treesitter.start = function() end
end)

-- 2. Bootstrap lazy.nvim (Standard Clone)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({ "git", "clone", "--branch=stable", "https://github.com/folke/lazy.nvim.git", lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({{ "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" }}, true, {})
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- 3. Plugin Configuration
require("lazy").setup({
  spec = {
    "itchyny/lightline.vim",
    "frazrepo/vim-rainbow",
    "christoomey/vim-tmux-navigator",
    { "dracula/vim", name = "dracula" },
  },
  git = { filter = false }, -- Fixes the Git 'packfile' error
})

-- 4. Classic Syntax Settings
-- Force standard regex highlighting and disable Treesitter-dependent features
vim.g.loaded_treesitter = 1
vim.g.markdown_recommended_style = 0 
vim.cmd("syntax enable")
vim.cmd("filetype plugin indent on")

-- 5. Core Editor Settings (Converted from your init.vim)
local opt = vim.opt

opt.termguicolors = true
opt.showmatch = true
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

opt.number = true
opt.relativenumber = true
opt.colorcolumn = "80"
opt.mouse = 'v'
opt.wildmode = { "longest", "list" }

opt.backup = false
opt.swapfile = false
opt.wrap = true
opt.linebreak = true

-- 6. Appearance
vim.g.rainbow_active = 1
vim.g.lightline = {
  colorscheme = 'dracula',
  active = {
    left = { { 'mode', 'paste' }, { 'readonly', 'filename', 'modified', 'charvaluehex' } }
  },
  component = { charvaluehex = '0x%B' },
}

vim.cmd.colorscheme("dracula")