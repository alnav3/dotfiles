return {

    {
        "mfussenegger/nvim-dap",

        dependencies = {
            "rcarriga/nvim-dap-ui",
        },

        config = function()
            Dapui = require("dapui").setup()
            Dap = require('dap')

            Dap.configurations.java = {
                {
                    type = 'java';
                    request = 'attach';
                    name = "Debug (Attach) - Remote";
                    hostName = "127.0.0.1";
                    port = 5005;
                },
            }
        end,
        keys = {
            {"<leader>db", function() require"dap".toggle_breakpoint() end, mode = "n"},
            {"<leader>dg",  ':lua require"dapui".toggle()<CR>', mode = "n"},
        }
    },
    --{"mfussenegger/nvim-jdtls"},
    {"nvim-java/nvim-java"},

    {
        "mfussenegger/nvim-dap",

        dependencies = {
            "rcarriga/nvim-dap-ui",
        },

        config = function()
            Dapui = require("dapui").setup()
            Dap = require('dap')

            Dap.configurations.java = {
                {
                    type = 'java';
                    request = 'attach';
                    name = "Debug (Attach) - Remote";
                    hostName = "127.0.0.1";
                    port = 5005;
                },
            }
        end,
        keys = {
            {"<leader>db", function() require"dap".toggle_breakpoint() end, mode = "n"},
            {"<leader>dg",  ':lua require"dapui".toggle()<CR>', mode = "n"},
        }
    },
    {
        "leoluz/nvim-dap-go",
        config = function()
            require("dap-go").setup() {
                delve = {
                    path = "dlv",
                    initialize_timeout_sec = 20,
                    args = {
                        "--", "CGO_CFLAGS=-O2", -- Pass CGO_CFLAGS as an argument
                    },
                    build_flags = {},
                    detached = vim.fn.has("win32") == 0,
                    cwd = nil,
                    -- Alternatively, use an environment variable setup if delve supports it
                    env = {
                        CGO_CFLAGS = "-O2",
                    },
                },
                tests = {
                    verbose = false,
                },
            }
        end,
    },
}

