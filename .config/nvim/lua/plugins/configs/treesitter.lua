local configs = require("nvim-treesitter.configs")

configs.setup({
	ensure_installed = { "lua", "vim", "vimdoc", "query", "javascript", "html", "typescript", "css" },
	sync_install = false,
	highlight = { enable = true },
	indent = { enable = true },
})
