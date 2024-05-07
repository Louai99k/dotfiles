local telescope = require("telescope")
local builtin = require("telescope.builtin")
local utils = require("utils.telescope")

telescope.load_extension("live_grep_args")

vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
vim.keymap.set(
	"n",
	"<leader>fs",
	telescope.extensions.live_grep_args.live_grep_args,
	{ noremap = true, desc = "Find In Files" }
)
vim.keymap.set(
	"n",
	"<leader>fg",
	utils.grep_at_current_tree_node,
	{ desc = "Find On Tree Cursor", silent = true, noremap = true }
)
vim.keymap.set("n", "<leader>fq", builtin.resume, { desc = "Resume Previous Telescope" })
vim.keymap.set("n", "<leader>fe", utils.search_word_under_cursor, { desc = "Resume Previous Telescope" })
