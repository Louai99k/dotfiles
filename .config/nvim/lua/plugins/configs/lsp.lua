require("mason").setup()
require("mason-lspconfig").setup()
require("mason-tool-installer").setup({
	ensure_installed = {
		"lua-language-server",
		"stylua",
		"prettier",
	},
})
require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		javascript = { "prettier" },
		typescript = { "prettier" },
		typescriptreact = { "prettier" },
		javascriptreact = { "prettier" },
		json = { "prettier" },
	},
})

vim.keymap.set({ "v", "n" }, "<leader>s", require("conform").format, { desc = "Format File" })

local lspconfig = require("lspconfig")

local lua_capabilities = require("cmp_nvim_lsp").default_capabilities()
lspconfig.lua_ls.setup({
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
		},
	},
	capabilities = lua_capabilities,
})
