local conform = require("conform")
local lspconfig = require("lspconfig")
local lua_capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Set Up
require("mason").setup()
require("mason-lspconfig").setup()
require("mason-tool-installer").setup({
	ensure_installed = {
		"lua-language-server",
		"stylua",
		"prettier",
	},
})
conform.setup({
	formatters_by_ft = {
		lua = { "stylua" },
		javascript = { "prettier" },
		typescript = { "prettier" },
		typescriptreact = { "prettier" },
		javascriptreact = { "prettier" },
		json = { "prettier" },
	},
})
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

-- Key Bindings
vim.keymap.set({ "v", "n" }, "<leader>lf", conform.format, { desc = "Format File" })
vim.keymap.set("n", "<leader>lg", vim.lsp.buf.definition, { desc = "Go To Definition" })
vim.keymap.set(
	"n",
	"<leader>lr",
	require("telescope.builtin").lsp_references,
	{ desc = "Show References", silent = true, noremap = true }
)

-- Events
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	callback = function(args)
		local filename = vim.fn.expand("%:p")

		if not filename:match("node_modules") then
			require("conform").format({ bufnr = args.buf })
		end
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function()
		vim.keymap.set("n", "<F2>", vim.lsp.buf.rename)
	end,
})
