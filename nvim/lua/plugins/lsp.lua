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
        "nvim-java/nvim-java",
    },
    config = function()
        local home = vim.fn.expand("$HOME")
        local java_path = vim.fn.expand("$HOME") .. "/.jdks/21.0.8"
        vim.filetype.add({ extension = { templ = "templ" } })
        require("mason").setup()
        -- configure java settings to use main java / required for nixOS
        -- Monkey-patch nvim-java's DAP auto-setup to prevent the
        -- "mainClass should already be present" crash. We still enable
        -- java_debug_adapter so the jar bundle gets loaded into jdtls,
        -- but we replace the fragile auto-config with our own in debug.lua.
        local java_dap = require("java-dap")
        local original_setup = java_dap.setup
        java_dap.setup = function()
            -- Only register the on_jdtls_attach event WITHOUT calling
            -- project_config.setup() or config_dap() automatically.
            -- debug.lua handles DAP configuration safely.
            local event = require("java-core.utils.event")
            event.on_jdtls_attach({
                callback = function()
                    -- Silently skip - debug.lua will handle this
                end,
            })
        end

        require("java").setup({
            jdk = {
                auto_install = false,
            },
            java_debug_adapter = {
                enable = true,
            },
            java_test = {
                enable = true,
            },
            spring_boot_tools = {
                enable = true,
            },
            java = {
                home = java_path,
                configuration = {
                    runtimes = {
                        {
                            name = "JavaSE-21",
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
                "jdtls",
                "pyright",
                "html",
                "htmx",
                "tailwindcss",
            },
            handlers = {
                function(name)
                    vim.lsp.config[name] = {}
                end,
                ["lua_ls"] = function ()
                    vim.lsp.config.lua_ls = {
                        settings = {
                            Lua = {
                                diagnostics = {
                                    globals = { "vim" }
                                },
                                workspace = {
                                    library = {
                                        [vim.fn.expand "$VIMRUNTIME/lua"] = true,
                                        [vim.fn.expand "$VIMRUNTIME/lua/vim/lsp"] = true,
                                        [vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types"] = true,
                                        [vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy"] = true,
                                        [vim.fn.expand "${3rd}/love2d/library"] = true,
                                    },
                                    maxPreload = 100000,
                                    preloadFileSize = 10000,

                                }
                            }
                        }
                    }
                end,
                ["jdtls"] = function()
                    vim.lsp.config.jdtls = {}
                end,
                ["htmx"] = function ()
                    vim.lsp.config.htmx = {
                        filetypes = { "html", "templ" },
                    }
                end,
                ["html"] = function()
                    vim.lsp.config.html = {
                        filetypes = { "html", "templ" },
                    }
                end,
                ["tailwindcss"] = function()
                    vim.lsp.config.tailwindcss = {
                        filetypes = { "templ", "astro", "javascript", "typescript", "react", "html" },
                        init_options = { userLanguages = { templ = "html" } },
                    }
                end,
            }
        })
        vim.lsp.config.nixd = {
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
        }
        vim.lsp.config.openscad_lsp = {}
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
