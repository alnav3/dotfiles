return{

    {
        "nvim-telescope/telescope.nvim",
        requires = { "nvim-lua/plenary.nvim" },
        keys = {
            -- Keymap para encontrar archivos
            { "<leader>pf", function() require('telescope.builtin').find_files() end, mode = "n" },
            -- Keymap para buscar una cadena
            {
                "<leader>ps",
                function()
                    require("telescope.builtin").grep_string({ search = vim.fn.input("Grep > ") })
                end,
                mode = "n",
                desc = "Grep String"
            },
        },
    },
    { "nvim-lua/plenary.nvim" },

}
