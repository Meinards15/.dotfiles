
-- # Lazy Setup # --
local lazypath = vim.fn.stdpath("data").."/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)


-- # Plugin Manager # --
require("lazy").setup({
  {
   "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
	style = "night",
	transparent = false,
    },
    config = function(_, opts)
	require("tokyonight").setup(opts)
	vim.cmd.colorscheme("tokyonight")
    end,
  },
  {
        "nvim-neo-tree/neo-tree.nvim",
        cmd = "Neotree",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        keys = {
            { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle file tree" },
            { "<leader>o", "<cmd>Neotree focus<cr>",  desc = "Focus file tree"  },
        },
        opts = {
            filesystem = {
                filtered_items = {
                    visible      = true,
                    hide_dotfiles = false,
                    hide_gitignored = false,
                },
                follow_current_file = { enabled = true },
            },
            window = { width = 30 },
        },
  }, 
  {
    'nvim-telescope/telescope.nvim', version = '*',
    lazy = false,
    dependencies = {
        'nvim-lua/plenary.nvim',
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    }
  },
  {
    "zk-org/zk-nvim",
    config = function()
        require("zk").setup({ picker = "fzf_lua" })

        local map = vim.keymap.set
        map("n", "<leader>zn", "<cmd>ZkNew<cr>")
        map("n", "<leader>zf", "<cmd>ZkNotes<cr>")
        map("n", "<leader>zt", "<cmd>ZkTags<cr>")
        map("n", "<leader>zl", "<cmd>ZkLinks<cr>")
        map("n", "<leader>zb", "<cmd>ZkBacklinks<cr>")
        map("v", "<leader>zn", ":'<,'>ZkNewFromTitleSelection<cr>")
    end
   },
   {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        opts = {
            options = {
                theme                = "tokyonight",
                globalstatus         = true,
                disabled_filetypes   = { statusline = { "dashboard" } },
                component_separators = { left = "|", right = "|" },
                section_separators   = { left = "", right = "" },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff", "diagnostics" },
                lualine_c = { { "filename", path = 1 } },
                lualine_x = { "encoding", "fileformat", "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
        },
    },
    {
        "stevearc/dressing.nvim",
        event = "VeryLazy",
        opts  = {},
    },
    {
        "akinsho/toggleterm.nvim",
        config = function()
            require("toggleterm").setup()
            local term = require("toggleterm.terminal").Terminal
            local test = term:new({
                cmd = "lazygit",
                direction = "horizontal",
                hidden = true,
            })

            vim.keymap.set("n", "<leader>lg", function()
                test:toggle()
            end, { desc = "t" })
        end
    },

})


