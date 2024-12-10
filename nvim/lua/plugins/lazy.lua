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
        branch = "main",
        dependencies = {
            { "github/copilot.vim" }, -- or github/copilot.vim
            { "nvim-telescope/telescope.nvim" }, -- Use telescope for help actions
            { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
        },
        opts = {
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
                "<leader>ap",
                function()
                    local actions = require("CopilotChat.actions")
                    require("CopilotChat.integrations.telescope").pick(actions.prompt_actions())
                end,
                desc = "CopilotChat - Prompt actions",
            },
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
    },
    {
        "ThePrimeagen/rfceez",
        config = function()
            local rfc = require("rfceez")
            rfc.setup()

            vim.keymap.set("n", "<leader>ma", function() rfc.add() end)
            vim.keymap.set("n", "<leader>md", function() rfc.rm() end)
            vim.keymap.set("n", "<leader>ms", function() rfc.show_notes() end)
            vim.keymap.set("n", "[m", function() rfc.nav_next() end)
            vim.keymap.set("n", "[[m", function() rfc.show_next() end)
        end

    },
    {
        "ibhagwan/fzf-lua",
        -- optional for icon support
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            -- calling `setup` is optional for customization
            require("fzf-lua").setup({})
        end
    }

}
