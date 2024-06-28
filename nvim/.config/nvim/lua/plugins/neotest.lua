return {
    {
        "nvim-neotest/neotest",
        dependencies = {
            "vim-test/vim-test",
            "nvim-lua/plenary.nvim",
            "antoinemadec/FixCursorHold.nvim",
            "nvim-treesitter/nvim-treesitter",
            "nvim-neotest/neotest-vim-test",
            "rcasia/neotest-java",
            "nvim-neotest/neotest-plenary",
        },
        config = function()
            local neotest = require("neotest")
            neotest.setup({
                adapters = {
                    require("neotest-vim-test")({ ignore_file_types = { "python", "vim" } }),
                    require("neotest-java")({
                        ignore_wrapper = false, -- whether to ignore maven/gradle wrapper
                    }),
                    require("neotest-plenary"),

                }
            })

            vim.keymap.set("n", "<leader>tc", function()
                neotest.run.run()
            end)

            vim.keymap.set("n", "<leader>tf", function()
                neotest.run.run(vim.fn.expand("%"))
            end)
        end,
    },
}

