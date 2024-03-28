vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "<leader><CR>", "o<ESC>", { desc = "insert new line" })

vim.keymap.set("i", "<C-h>", "<LEFT>")
vim.keymap.set("i", "<C-j>", "<DOWN>")
vim.keymap.set("i", "<C-k>", "<UP>")
vim.keymap.set("i", "<C-l>", "<RIGHT>")
