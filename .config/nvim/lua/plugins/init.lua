local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
	-- Theme
	{
		"catppuccin/nvim",
		priority = 1000,
		config = function()
			vim.o.background = "dark"
			vim.cmd([[colorscheme catppuccin-mocha]])
		end,
	},
	-- Mason & LSP
	{
		"williamboman/mason.nvim",
		dependencies = {
			"neovim/nvim-lspconfig",
			"williamboman/mason-lspconfig.nvim",
			"stevearc/conform.nvim",
		},
		init = function()
			require("plugins.configs.lsp")
		end,
	},
	-- Which Key
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		init = function()
			require("plugins.configs.which-key")
		end,
		opt = {},
	},
	-- Auto Complete
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-vsnip",
			"hrsh7th/vim-vsnip",
			"rafamadriz/friendly-snippets",
		},
		init = function()
			require("plugins.configs.cmp")
		end,
	},
	-- Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		init = function()
			require("plugins.configs.treesitter")
		end,
	},
	-- Lua Line
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		init = function()
			require("lualine").setup()
		end,
	},
	-- Tree View
	{
		"nvim-tree/nvim-tree.lua",
		init = function()
			require("plugins.configs.nvim-tree")
		end,
	},
	-- Buffer Line
	{
		"akinsho/bufferline.nvim",
		init = function()
			require("plugins.configs.bufferline")
		end,
	},
	-- Telescope
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-live-grep-args.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			"BurntSushi/ripgrep",
		},
		init = function()
			require("plugins.configs.telescope")
		end,
	},
	-- Ts Tools
	{
		"pmizio/typescript-tools.nvim",
		init = function()
			require("plugins.configs.tstools")
		end,
	},
	-- Git plugins
	{
		"tpope/vim-fugitive",
		config = function()
			require("plugins.configs.git")
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		init = function()
			require("gitsigns").setup()
		end,
	},
	{
		"numToStr/Comment.nvim",
		config = function()
			require("plugins.configs.comment")
		end,
		lazy = false,
	},
	-- Colorizer
	{
		"norcalli/nvim-colorizer.lua",
		config = function()
			require("colorizer").setup()
		end,
	},
}

require("lazy").setup(plugins)
