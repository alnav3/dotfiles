return {
    {
        url = "https://gitlab.com/schrieveslaach/sonarlint.nvim",
        ft = {"python", "go", "java"},
        dependencies = {
            "mfussenegger/nvim-jdtls",
            "williamboman/mason.nvim"
        },
        config = function()
            local sonar_language_server_path = "/Users/alexnavia3/.dotfiles/data/nvim/mason/packages/sonarlint-language-server"
            local analyzers_path = sonar_language_server_path .. "/extension/analyzers"
            require("sonarlint").setup({
                server = {
                    cmd = {
                        sonar_language_server_path .. "/sonarlint-language-server",
                        "-stdio",
                        "-analyzers",
                        vim.fn.expand(analyzers_path .. "/sonarpython.jar"),
                        vim.fn.expand(analyzers_path .. "/sonargo.jar"),
                        vim.fn.expand(analyzers_path .. "/sonarjava.jar"),

                    }
                },
                filetypes = {
                    "python",
                    "go",
                    "java"
                }
            })
        end
    }
}
