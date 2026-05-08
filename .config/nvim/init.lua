-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Configure your plugins
require("lazy").setup({
  "itchyny/lightline.vim",
  "frazrepo/vim-rainbow",
  "christoomey/vim-tmux-navigator",
  { "dracula/vim", name = "dracula" },
  
  -- Modern additions to fix your current errors
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" }, 
})


