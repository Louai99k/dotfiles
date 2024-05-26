local conform = require("conform")
local lspconfig = require("lspconfig")
local lua_capabilities = require("cmp_nvim_lsp").default_capabilities()
local telescope_builtin = require("telescope.builtin")

-- Set Up
require("mason").setup()
require("mason-lspconfig").setup({
	ensure_installed = {
		"lua_ls",
		"clangd",
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
		cpp = { "clang-format" },
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
lspconfig.clangd.setup({})

-- Key Bindings
vim.keymap.set({ "v", "n" }, "<leader>lf", conform.format, { desc = "Format File" })
vim.keymap.set("n", "<leader>lg", telescope_builtin.lsp_definitions, { desc = "Go To Definition" })
vim.keymap.set(
	"n",
	"<leader>lr",
	telescope_builtin.lsp_references,
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
