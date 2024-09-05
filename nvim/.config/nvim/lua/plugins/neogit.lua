return {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",         -- required
      "sindrets/diffview.nvim",        -- optional - Diff integration
      "nvim-telescope/telescope.nvim", -- optional
    },
    config = function()
      require("neogit").setup()
    end,
    keys = {
      { "<leader>gs", function() require('neogit').open() end, {silent = true, noremap = true} },
      { "<leader>gc", ":Neogit commit<CR>", {silent = true, noremap = true} },
      { "<leader>gp", ":Neogit pull<CR>", {silent = true, noremap = true} },
      { "<leader>gP", ":Neogit push<CR>", {silent = true, noremap = true} },
      { "<leader>gb", ":Telescope git_branches<CR>", {silent = true, noremap = true} },
      { "<leader>gB", ":G blame<CR>", {silent = true, noremap = true} }
    }
}
