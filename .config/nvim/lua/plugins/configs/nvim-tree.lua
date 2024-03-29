vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.termguicolors = true

require("nvim-tree").setup({
	filters = {
		dotfiles = false,
		git_ignored = false,
	},
	renderer = { icons = { glyphs = { git = { untracked = "+" } } } },
})

vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "Focus Tree View" })
vim.keymap.set("n", "<leader>n", "<cmd>NvimTreeFindFileToggle<CR>", { desc = "Find File In Tree" })
