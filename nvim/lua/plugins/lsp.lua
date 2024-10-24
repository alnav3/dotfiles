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
        "nvim-java/nvim-java",
    },
    config = function()
        local home = vim.fn.expand("$HOME")
        local java_path = vim.fn.expand("$HOME") .. "/.jdks/17.0.9"
        vim.filetype.add({ extension = { templ = "templ" } })
        require("mason").setup()
        -- configure java settings to use main java / required for nixOS
        require("java").setup({
            jdk = {
                -- install jdk using mason.nvim
                auto_install = false,
            },
            java = {
                home = java_path,
                configuration = {
                    runtimes = {
                        {
                            name = "JavaSE-17",
                            path = java_path,
                            default = true,
                        },
                    },
                },
            },
        })
        require("mason-lspconfig").setup({
            ensure_installed = {
                "lua_ls",
                "gopls",
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
                    require("lspconfig").jdtls.setup({})
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
                ["groovyls"] = function ()
                    local lspconfig = require("lspconfig")
                    lspconfig.groovyls.setup {
                        filetypes = { "groovy" },
                        settings = {
                            groovy = {
                                classpath = {
                                    home .. "/dev/ewe-git/bonita/dependencies/extensions", --TODO: add the path to the groovy library
                                }
                            }
                        }
                    }
                end,
                ["htmx"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.htmx.setup({
                        filetypes = { "html", "templ" },
                    })
                end,
            }
        })
        require("lspconfig").nixd.setup({
            cmd = {"nixd"},
            settings = {
                nixd = {
                    nixpkgs = {
                        expr = "import <nixpkgs> { }",
                    },
                    formatting = {
                        command = "alejandra",
                    },
                },
            },
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
    end,
}
