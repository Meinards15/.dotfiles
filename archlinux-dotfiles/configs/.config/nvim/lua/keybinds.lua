
-- #### [ KEYBINDS.LUA ] #### --

local map = vim.keymap.set

-- ### Setup MapLeader ###
vim.g.mapleader      = " "
vim.g.maplocalleader = " "


-- ### Keybinds ###
--- ## General Commands ##
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>close<cr>", { desc = "Close Current Window" })
map("n", "<leader>Q", "<cmd>qa!<cr>", { desc = "Quit All" })
map("n", "<Esc>", "<cmd>nohl<cr>", { desc = "Clear search highlight" })
map({"n", "v"}, "d", '"_d', { desc = "Delete without yank" })
map("n", "dd", '"_dd', { desc = "Delete line without yank" })
map("x", "p", [["_dP]], { desc = "Paste without yank" })
map({ "n", "v" }, "<Del>", '"_d', { desc = "Delete without yanking" })
map("n", "<leader>nf", function()
    local dir = vim.fn.expand("%:p:h")
    local tgrande = vim.fn.input("New file: ", dir .. "/")
    if tgrande ~= "" then
        vim.cmd("e " .. tgrande)
    end
end, { desc = "Create New File in Current Directory" })


--- ## Navigation ##
------- # Moving Window / Move Splits #
map("n", "<leader>h", "<C-w>h", { desc = "Move to left window" })
map("n", "<leader>l", "<C-w>l", { desc = "Move to lower window" })
map("n", "<leader>k", "<C-w>k", { desc = "Move to upper window" })
map("n", "<leader>l", "<C-w>l", { desc = "Move to right window" })
map("n", "<leader><Left>", "<C-w>h", { desc = "Move to left window" })
map("n", "<leader><Down>", "<C-w>j", { desc = "Move to lower window" })
map("n", "<leader><Up>", "<C-w>k", { desc = "Move to upper window" })
map("n", "<leader><Right>", "<C-w>l", { desc = "Move to right window" })
map("n", "<leader>=", "<C-w>=", { desc = "Equalize window sizes" })

--- ## Opening Window / Open Split ##
map("n", "<leader><S-Up>", "<cmd>split<cr>", { desc = "Split above (horizontal)" })
map("n", "<leader><S-Down>", "<cmd>below split<cr>", { desc = "Split below (horizontal)" })
map("n", "<leader><S-Left>", "<cmd>vsplit<cr>", { desc = "Split left (vertical)" })
map("n", "<leader><S-Right>", "<cmd>rightbelow vsplit<cr>", { desc = "Split right (vertical)" })

--- ## Resizing Window / Resize splits ##
map("n", "<leader><S-Up>", "<cmd>resize +2<cr>", { desc = "Increase height" })
map("n", "<leader><S-Down>", "<cmd>resize -2<cr>", { desc = "Decrease height" })
map("n", "<leader><S-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
map("n", "<leader><S-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })

-- Close window in direction (using hjkl)
map("n", "<leader>h", "<C-w>h<C-w>q", { desc = "Close left window" })
map("n", "<leader>j", "<C-w>j<C-w>q", { desc = "Close below window" })
map("n", "<leader>k", "<C-w>k<C-w>q", { desc = "Close above window" })
map("n", "<leader>l", "<C-w>l<C-w>q", { desc = "Close right window" })

-- Using arrow keys
map("n", "<leader><Left>", "<C-w>h<C-w>q", { desc = "Close left window" })
map("n", "<leader><Down>", "<C-w>j<C-w>q", { desc = "Close below window" })
map("n", "<leader><Up>", "<C-w>k<C-w>q", { desc = "Close above window" })
map("n", "<leader><Right>", "<C-w>l<C-w>q", { desc = "Close right window" })

--- ## Buffers ##
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

--- ## Move lines ##
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

--- ## Better indent ##
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

--- ## Keep cursor centered ##
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down centered" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up centered" })
map("n", "n", "nzzzv", { desc = "Next search centered" })
map("n", "N", "Nzzzv", { desc = "Prev search centered" })

--- # System clipboard #
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to clipboard" })
map("n", "<leader>Y", [["+Y]], { desc = "Yank line to clipboard" })

--- # Splits #
map("n", "<leader>sv", "<cmd>vsplit<cr>", { desc = "Split vertical" })
map("n", "<leader>sh", "<cmd>split<cr>", { desc = "Split horizontal" })

--- # Terminal #
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

--- # Quickfix #
map("n", "]q", "<cmd>cnext<cr>", { desc = "Next quickfix" })
map("n", "[q", "<cmd>cprev<cr>", { desc = "Prev quickfix" })

--- # Diagnostics #
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })

--- # Lazy #
map("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Open Lazy" }) 





