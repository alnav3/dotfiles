return {
    { "rose-pine/neovim" },
    {
        "mbbill/undotree",
        keys = {
            {"<leader>u", vim.cmd.UndotreeToggle, mode = "n"}
        }
    },
    { "ThePrimeagen/vim-be-good" },
    {
        "github/copilot.vim",
        lazy = false,
        priority = 700
    },
    {
        "numToStr/FTerm.nvim",
        keys = {
            {"<leader>ft", "<cmd>lua require('FTerm').toggle()<cr>", mode = "n"},
            {"<leader>mtc", "<cmd>lua require('FTerm').run('mvn test -Dtest=' .. vim.fn.expand('%:t:r'))<cr>", mode = "n"},
            {"<leader>msn", "<cmd>lua require('FTerm').run('mvn spring-boot:run')<cr>", mode = "n"},
        }
    },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        branch = "canary",
        dependencies = {
            { "github/copilot.vim" }, -- or github/copilot.vim
            { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
        },
        opts = {
            debug = true, -- Enable debugging
            window = {
                layout = 'float',
                width = 1,
                height = 0.8,
                row = 1
            },

        },
        -- See Configuration section for rest
        keys = {
            {
                "<leader>cc",
                function() vim.cmd('CopilotChatToggle') end,
                mode = "n",
                desc = "Toggle Copilot Chat"
            },
        }
        -- See Commands section for default commands if you want to lazy load on them
    },
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {},
        keys = {
            {"<leader>tt", "<cmd>TroubleToggle<cr>", mode = "n"},
        }
    },
    { "nvim-tree/nvim-web-devicons" },
    {
        "danymat/neogen",
        dependencies = "nvim-treesitter/nvim-treesitter",
        config = true,
        -- follow only stable versions
        version = "*",
        keys = {
            {"<leader>g", ":lua require('neogen').generate()<CR>", mode = "n"}
        }
    }
}
