return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "mfussenegger/nvim-dap",
        "rcarriga/nvim-dap-ui",
    },
    config = function()
        vim.filetype.add({ extension = { templ = "templ" } })
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = {
                "lua_ls",
                "gopls",
                "jdtls",
            },
            handlers = {
                function(name)
                    require("lspconfig")[name].setup({})
                end,
                ["lua_ls"] = function ()
                    local lspconfig = require("lspconfig")
                    lspconfig.lua_ls.setup {
                        settings = {
                            Lua = {
                                diagnostics = {
                                    globals = { "vim" }
                                }
                            }
                        }
                    }
                end,
                ["jdtls"] = function()
                    local lspconfig = require("lspconfig")
                    local lombok_path = vim.fn.stdpath('data') .. "/mason/packages/jdtls/lombok.jar"

                    lspconfig.jdtls.setup {
                        cmd = {
                            "/Users/alexnavia3/.dotfiles/data/nvim/mason/bin/jdtls",
                            "--jvm-arg=" .. string.format("-javaagent:" ..lombok_path),
                            "-configuration /Users/alexnavia3/.cache/jdtls/config",
                            "-data /Users/alexnavia3/.cache/jdtls/workspace",
                        },
                        init_options = {
                            bundles = {
                                vim.fn.glob(vim.fn.stdpath('data') .. "/mason/packages/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar", 1)
                            }
                        },
                    }
                end,
                ["html"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.html.setup({
                        filetypes = { "html", "templ" },
                    })
                end,
                ["tailwindcss"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.tailwindcss.setup({
                        filetypes = { "templ", "astro", "javascript", "typescript", "react" },
                        init_options = { userLanguages = { templ = "html" } },
                    })
                end,
                ["htmx"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.htmx.setup({
                        filetypes = { "html", "templ" },
                    })
                end,
            }
        })
        -- Set up nvim-cmp.
        local cmp = require'cmp'
        local cmd_select = {behavior = cmp.SelectBehavior.Select}

        cmp.setup({
            snippet = {
                -- REQUIRED - you must specify a snippet engine
                expand = function(args)
                    require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ['<C-p>'] = cmp.mapping.select_prev_item(cmd_select),
                ['<C-n>'] = cmp.mapping.select_next_item(cmd_select),
                ['<C-y>'] = cmp.mapping.confirm({select = true}),
                ['<C-Space>'] = cmp.mapping.complete(),
            }),
            sources = cmp.config.sources({
                { name = 'nvim_lsp' },
                { name = 'luasnip' }, -- For luasnip users.
            }, {
                { name = 'buffer' },
            })
        })
        require("jdtls").setup_dap({ hotcodereplace = 'auto' })


    end,
}
