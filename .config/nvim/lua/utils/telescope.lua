local M = {}
local telescope = require("telescope")
local builtin = require("telescope.builtin")

M.grep_at_current_tree_node = function()
	local node = require("nvim-tree.lib").get_node_at_cursor()
	if not node then
		return
	end
	telescope.extensions.live_grep_args.live_grep_args({ search_dirs = { node.absolute_path } })
end

M.search_word_under_cursor = function()
	builtin.grep_string()
end

return M
