local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- Configuration de LazyVim
    {
      "LazyVim/LazyVim",
      import = "lazyvim.plugins",
      opts = {
		colorscheme = "tokyonight-night",  -- Version avec meilleure transparence
        transparency = true,
      },
    },

    -- Plugin gruvbox (version moderne avec support natif de la transparence)
    {
      "ellisonleao/gruvbox.nvim",
      priority = 1000, -- Charge en premier
      config = function()
        require("gruvbox").setup({
		--transparent_mode = true, -- Fond transparent
			--contrast = "hard", -- Optionnel: meilleur contraste
		transparent_mode = true,
		overrides = {
        Normal = { bg = "NONE" }, -- Force un vrai transparent
        SignColumn = { bg = "NONE" },
			}
        })
      end,
    },

    -- Vos plugins personnalisés
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "gruvbox" } }, -- Garantit l'installation
  checker = { enabled = true, notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

-- Configuration de secours pour la transparence
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    -- Applique la transparence même si le thème ne le supporte pas nativement
    vim.cmd([[
      highlight Normal guibg=NONE ctermbg=NONE
      highlight NonText guibg=NONE ctermbg=NONE
      highlight LineNr guibg=NONE ctermbg=NONE
      highlight SignColumn guibg=NONE ctermbg=NONE
      highlight EndOfBuffer guibg=NONE ctermbg=NONE
    ]])
  end,
})
