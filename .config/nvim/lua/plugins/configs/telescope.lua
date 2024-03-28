require("telescope").load_extension("live_grep_args")

local builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
vim.keymap.set(
	"n",
	"<leader>fs",
	require("telescope").extensions.live_grep_args.live_grep_args,
	{ noremap = true, desc = "Find In Files" }
)

vim.keymap.set(
	"n",
	"<leader>fg",
	":lua require('utils.telescope').grepAtCurrentTreeNode()<CR>",
	{ desc = "Find On Tree Cursor" }
)
vim.keymap.set("n", "<leader>fq", builtin.resume, { desc = "Resume Previous Telescope" })
