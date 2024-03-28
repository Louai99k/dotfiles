require("typescript-tools").setup({
	root_dir = require("lspconfig.util").root_pattern(".git"),
	settings = {
		separate_diagnostic_server = false,
		tsserver_max_memory = 2048,
		jsx_close_tag = {
			enable = true,
			filetypes = { "javascriptreact", "typescriptreact" },
		},
	},
})
