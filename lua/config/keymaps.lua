local map = vim.keymap.set

-- Déplacer ligne vers le bas
map("n", "<A-Down>", ":m .+1<CR>==", { desc = "Move line down" })
map("i", "<A-Down>", "<Esc>:m .+1<CR>==gi", { desc = "Move line down" })
map("v", "<A-Down>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })

-- Déplacer ligne vers le haut
map("n", "<A-Up>", ":m .-2<CR>==", { desc = "Move line up" })
map("i", "<A-Up>", "<Esc>:m .-2<CR>==gi", { desc = "Move line up" })
map("v", "<A-Up>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
