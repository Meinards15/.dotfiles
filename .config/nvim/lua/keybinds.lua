
-- # Keybinds #--

local map = vim.keymap.set

-- # Setup MapLeader
vim.g.mapleader      = " "
vim.g.maplocalleader = " "

map("n", "<leader>w", "<cmd>w<cr>",          { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>",          { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qa!<cr>",        { desc = "Quit all" })
map("n", "<Esc>",     "<cmd>nohl<cr>",       { desc = "Clear search highlight" })


-- # Navigation
map("n", "<C-h>", "<C-w>h",                  { desc = "Move to left window" })
map("n", "<C-l>", "<C-w>l",                  { desc = "Move to right window" })
map("n", "<C-j>", "<C-w>j",                  { desc = "Move to lower window" })
map("n", "<C-k>", "<C-w>k",                  { desc = "Move to upper window" })

-- ── Resize splits ─────────────────────────────────────────────
map("n", "<C-Up>",    "<cmd>resize +2<cr>",          { desc = "Increase height" })
map("n", "<C-Down>",  "<cmd>resize -2<cr>",          { desc = "Decrease height" })
map("n", "<C-Left>",  "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })

-- ── Buffers ───────────────────────────────────────────────────
map("n", "<S-h>",     "<cmd>bprevious<cr>",  { desc = "Prev buffer" })
map("n", "<S-l>",     "<cmd>bnext<cr>",      { desc = "Next buffer" })
map("n", "<leader>bd","<cmd>bdelete<cr>",    { desc = "Delete buffer" })

-- ── Move lines ────────────────────────────────────────────────
map("v", "J", ":m '>+1<cr>gv=gv",           { desc = "Move selection down" })
map("v", "K", ":m '<-2<cr>gv=gv",           { desc = "Move selection up" })

-- ── Better indent ─────────────────────────────────────────────
map("v", "<", "<gv",                         { desc = "Indent left" })
map("v", ">", ">gv",                         { desc = "Indent right" })

-- ── Keep cursor centered ──────────────────────────────────────
map("n", "<C-d>", "<C-d>zz",                { desc = "Scroll down centered" })
map("n", "<C-u>", "<C-u>zz",                { desc = "Scroll up centered" })
map("n", "n",     "nzzzv",                  { desc = "Next search centered" })
map("n", "N",     "Nzzzv",                  { desc = "Prev search centered" })

-- ── Paste without losing register ─────────────────────────────
map("x", "<leader>p", [["_dP]],             { desc = "Paste without yank" })

-- ── System clipboard ──────────────────────────────────────────
map({ "n", "v" }, "<leader>y", [["+y]],     { desc = "Yank to clipboard" })
map("n", "<leader>Y", [["+Y]],              { desc = "Yank line to clipboard" })

-- ── Splits ────────────────────────────────────────────────────
map("n", "<leader>sv", "<cmd>vsplit<cr>",   { desc = "Split vertical" })
map("n", "<leader>sh", "<cmd>split<cr>",    { desc = "Split horizontal" })

-- ── Terminal ──────────────────────────────────────────────────
map("t", "<Esc><Esc>", "<C-\\><C-n>",       { desc = "Exit terminal mode" })

-- ── Quickfix ──────────────────────────────────────────────────
map("n", "]q", "<cmd>cnext<cr>",            { desc = "Next quickfix" })
map("n", "[q", "<cmd>cprev<cr>",            { desc = "Prev quickfix" })

-- ── Diagnostics ───────────────────────────────────────────────
map("n", "]d", vim.diagnostic.goto_next,    { desc = "Next diagnostic" })
map("n", "[d", vim.diagnostic.goto_prev,    { desc = "Prev diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })


-- # Lazy

map("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Open Lazy" }) 





