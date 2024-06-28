return {
    "dsych/blanket.nvim",
    configure = function()
        require("blanket").setup({
            report_path = vim.fn.getcwd().."/target/site/jacoco/jacoco.xml",
            filetypes = "java",
            signs = {
                priority = 10,
                incomplete_branch = "█",
                uncovered = "█",
                covered = "█",
                sign_group = "Blanket"

                -- and the highlights for each sign!
                -- useful for themes where below highlights are similar
            },
        })
    end
}
