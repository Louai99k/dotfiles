vim.api.nvim_set_keymap(
	"n",
	"<leader>gc",
	':lua require("utils.git").commitStagedFiles()<CR>',
	{ noremap = true, silent = true }
)
