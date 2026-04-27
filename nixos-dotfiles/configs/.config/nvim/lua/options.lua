
-- # Options # --

local opt = vim.opt


-- # UI
opt.number         = true          -- line numbers
opt.relativenumber = true          -- relative line numbers
opt.signcolumn     = "yes"         -- always show sign column
opt.cursorline     = true          -- highlight current line
opt.termguicolors  = true          -- true color support
opt.showmode       = false         -- hide -- INSERT -- (statusline handles it)
opt.scrolloff      = 8             -- keep 8 lines above/below cursor
opt.sidescrolloff  = 8
opt.wrap           = false         -- no line wrap
opt.colorcolumn    = "80"          -- vertical ruler at 80
opt.pumheight      = 10            -- max items in completion popup
opt.laststatus     = 3             -- global statusline

-- ── Indent ────────────────────────────────────────────────────
opt.tabstop        = 4
opt.shiftwidth     = 4
opt.softtabstop    = 4
opt.expandtab      = true          -- spaces not tabs
opt.smartindent    = true
opt.breakindent    = true

-- ── Search ────────────────────────────────────────────────────
opt.ignorecase     = true
opt.smartcase      = true          -- case-sensitive if uppercase used
opt.hlsearch       = false         -- don't persist highlight after search
opt.incsearch      = true

-- ── Files ─────────────────────────────────────────────────────
opt.undofile       = true          -- persistent undo
opt.swapfile       = false
opt.backup         = false
opt.updatetime     = 250           -- faster CursorHold events
opt.timeoutlen     = 300           -- faster which-key popup

-- ── Splits ────────────────────────────────────────────────────
opt.splitbelow     = true
opt.splitright     = true

-- ── Clipboard ─────────────────────────────────────────────────
opt.clipboard      = "unnamedplus" -- sync with system clipboard

-- ── Appearance ────────────────────────────────────────────────
opt.fillchars      = { eob = " " } -- hide ~ at end of buffer
opt.list           = true
opt.listchars      = { tab = "» ", trail = "·", nbsp = "␣" }

