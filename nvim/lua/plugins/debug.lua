return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "theHamsta/nvim-dap-virtual-text",
        "williamboman/mason.nvim",
    },
    keys = {
        { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
        { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Conditional Breakpoint" },
        { "<leader>dc", function() require("dap").continue() end, desc = "Continue / Start" },
        { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
        { "<leader>do", function() require("dap").step_over() end, desc = "Step Over" },
        { "<leader>dO", function() require("dap").step_out() end, desc = "Step Out" },
        { "<leader>dr", function() require("dap").restart() end, desc = "Restart" },
        { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
        { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
        { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
        { "<leader>de", function() require("dapui").eval() end, desc = "Eval Under Cursor", mode = { "n", "v" } },
        { "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
        { "<leader>dh", function() require("dap.ui.widgets").hover() end, desc = "Hover Variables", mode = { "n", "v" } },
    },
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")
        local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
        local mason_packages = vim.fn.stdpath("data") .. "/mason/packages"

        -- Ensure debug adapters are installed via Mason
        local registry = require("mason-registry")
        local ensure_installed = { "delve" }
        for _, pkg_name in ipairs(ensure_installed) do
            local ok, pkg = pcall(registry.get_package, pkg_name)
            if ok and not pkg:is_installed() then
                pkg:install()
            end
        end

        -------------------------------------------------------------------
        -- DAP UI
        -------------------------------------------------------------------
        dapui.setup({
            icons = { expanded = "-", collapsed = "+", current_frame = ">" },
            layouts = {
                {
                    elements = {
                        { id = "scopes", size = 0.25 },
                        { id = "breakpoints", size = 0.25 },
                        { id = "stacks", size = 0.25 },
                        { id = "watches", size = 0.25 },
                    },
                    position = "left",
                    size = 40,
                },
                {
                    elements = {
                        { id = "repl", size = 0.5 },
                        { id = "console", size = 0.5 },
                    },
                    position = "bottom",
                    size = 10,
                },
            },
        })

        require("nvim-dap-virtual-text").setup({ commented = true })

        -- Auto open/close DAP UI
        dap.listeners.before.attach.dapui_config = function() dapui.open() end
        dap.listeners.before.launch.dapui_config = function() dapui.open() end
        dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
        dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

        -- Signs
        vim.fn.sign_define("DapBreakpoint", { text = "B", texthl = "DiagnosticError" })
        vim.fn.sign_define("DapBreakpointCondition", { text = "C", texthl = "DiagnosticWarn" })
        vim.fn.sign_define("DapLogPoint", { text = "L", texthl = "DiagnosticInfo" })
        vim.fn.sign_define("DapStopped", { text = ">", texthl = "DiagnosticOk", linehl = "DapStoppedLine" })
        vim.fn.sign_define("DapBreakpointRejected", { text = "R", texthl = "DiagnosticError" })
        vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

        -------------------------------------------------------------------
        -- Go (delve) - manual configuration
        -- dlv is installed by Mason but not in system PATH
        -------------------------------------------------------------------
        local dlv_path = mason_bin .. "/dlv"

        dap.adapters.go = function(callback, config)
            local stdout = vim.uv.new_pipe(false)
            local stderr = vim.uv.new_pipe(false)
            local handle
            local port = 38697

            handle, _ = vim.uv.spawn(dlv_path, {
                stdio = { nil, stdout, stderr },
                args = { "dap", "-l", "127.0.0.1:" .. port },
                detached = true,
            }, function(code)
                if stdout then stdout:close() end
                if stderr then stderr:close() end
                if handle then handle:close() end
            end)

            assert(handle, "Error running dlv: " .. dlv_path)

            -- Wait for delve to start
            vim.defer_fn(function()
                callback({ type = "server", host = "127.0.0.1", port = port })
            end, 100)
        end

        -- NixOS: glibc's _FORTIFY_SOURCE requires -O but delve's debug
        -- build uses -gcflags all=-N -l (no optimization). Override the
        -- CGO C flags to disable _FORTIFY_SOURCE and drop -Werror=cpp.
        local nixos_env = {
            CGO_CFLAGS = "-U_FORTIFY_SOURCE -Wno-cpp",
        }

        dap.configurations.go = {
            {
                type = "go",
                name = "Debug File",
                request = "launch",
                program = "${file}",
                env = nixos_env,
            },
            {
                type = "go",
                name = "Debug Package",
                request = "launch",
                program = "${fileDirname}",
                env = nixos_env,
            },
            {
                type = "go",
                name = "Debug Test File",
                request = "launch",
                mode = "test",
                program = "${file}",
                env = nixos_env,
            },
            {
                type = "go",
                name = "Debug Test Package",
                request = "launch",
                mode = "test",
                program = "${fileDirname}",
                env = nixos_env,
            },
        }

        -------------------------------------------------------------------
        -- Python (debugpy)
        -- On NixOS, Mason and pip can't install into the immutable store,
        -- so we maintain a small dedicated venv for debugpy.
        -------------------------------------------------------------------
        local debugpy_venv = vim.fn.stdpath("data") .. "/debugpy-venv"
        local debugpy_python = debugpy_venv .. "/bin/python"

        -- Bootstrap the venv + debugpy if it doesn't exist yet
        if vim.fn.executable(debugpy_python) ~= 1 then
            vim.notify("debugpy: creating venv at " .. debugpy_venv .. " (first-time setup)", vim.log.levels.INFO)
            vim.fn.system({ "python3", "-m", "venv", debugpy_venv })
            vim.fn.system({ debugpy_python, "-m", "pip", "install", "debugpy" })
        end

        dap.adapters.python = {
            type = "executable",
            command = debugpy_python,
            args = { "-m", "debugpy.adapter" },
        }

        dap.configurations.python = {
            {
                type = "python",
                name = "Debug File",
                request = "launch",
                program = "${file}",
                pythonPath = function()
                    -- Use activated venv if available, else system python
                    local venv = os.getenv("VIRTUAL_ENV")
                    if venv then
                        return venv .. "/bin/python"
                    end
                    return "python3"
                end,
            },
            {
                type = "python",
                name = "Debug File with Arguments",
                request = "launch",
                program = "${file}",
                args = function()
                    local input = vim.fn.input("Arguments: ")
                    return vim.split(input, " ")
                end,
                pythonPath = function()
                    local venv = os.getenv("VIRTUAL_ENV")
                    if venv then
                        return venv .. "/bin/python"
                    end
                    return "python3"
                end,
            },
            {
                type = "python",
                name = "Debug Module",
                request = "launch",
                module = function()
                    return vim.fn.input("Module name: ")
                end,
                pythonPath = function()
                    local venv = os.getenv("VIRTUAL_ENV")
                    if venv then
                        return venv .. "/bin/python"
                    end
                    return "python3"
                end,
            },
            {
                type = "python",
                name = "Attach to Remote",
                request = "attach",
                connect = {
                    host = "127.0.0.1",
                    port = 5678,
                },
            },
        }

        -------------------------------------------------------------------
        -- Java - uses nvim-java's jdtls debug bundle (loaded via lsp.lua)
        -- The auto-setup is monkey-patched in lsp.lua to prevent crashes.
        -- Here we configure DAP safely when jdtls is ready.
        -------------------------------------------------------------------
        local java_dap_configured = false

        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if not client or client.name ~= "jdtls" then
                    return
                end
                if java_dap_configured then
                    return
                end
                java_dap_configured = true

                -- Wait for jdtls to fully index the project before
                -- resolving main classes.
                vim.defer_fn(function()
                    -- Set up the adapter - asks jdtls to start a debug session
                    dap.adapters.java = function(callback)
                        local clients = vim.lsp.get_clients({ name = "jdtls" })
                        if #clients == 0 then
                            vim.notify("jdtls not running", vim.log.levels.ERROR)
                            return
                        end

                        local jdtls = clients[1]
                        jdtls:exec_cmd(
                            { command = "vscode.java.startDebugSession" },
                            { bufnr = vim.api.nvim_get_current_buf() },
                            function(err, port)
                                if err then
                                    vim.notify("Failed to start debug session: " .. vim.inspect(err), vim.log.levels.ERROR)
                                    return
                                end
                                callback({
                                    type = "server",
                                    host = "127.0.0.1",
                                    port = port,
                                })
                            end
                        )
                    end

                    -- Start with just the attach config (always works)
                    dap.configurations.java = {
                        {
                            type = "java",
                            request = "attach",
                            name = "Attach to Remote (port 5005)",
                            hostName = "127.0.0.1",
                            port = 5005,
                        },
                    }

                    -- Try to resolve main classes for launch configs
                    local ok, _ = pcall(function()
                        local clients = vim.lsp.get_clients({ name = "jdtls" })
                        if #clients == 0 then return end
                        local jdtls = clients[1]

                        jdtls:exec_cmd(
                            { command = "vscode.java.resolveMainClass" },
                            { bufnr = vim.api.nvim_get_current_buf() },
                            function(err, main_classes)
                                if err or not main_classes then return end
                                for _, main in ipairs(main_classes) do
                                    table.insert(dap.configurations.java, {
                                        type = "java",
                                        request = "launch",
                                        name = "Launch " .. (main.mainClass or "Unknown"),
                                        mainClass = main.mainClass,
                                        projectName = main.projectName,
                                    })
                                end
                            end
                        )
                    end)
                    if not ok then
                        vim.notify("Java DAP: could not resolve main classes (project still loading)", vim.log.levels.INFO)
                    end
                end, 8000) -- 8 seconds for jdtls to finish indexing
            end,
        })

        -- Manual command to re-resolve main classes
        vim.api.nvim_create_user_command("JavaDapConfig", function()
            java_dap_configured = false
            local clients = vim.lsp.get_clients({ name = "jdtls" })
            if #clients == 0 then
                vim.notify("jdtls not running", vim.log.levels.WARN)
                return
            end
            -- Trigger the autocmd logic again immediately
            vim.defer_fn(function()
                java_dap_configured = true
                local jdtls = clients[1]

                dap.adapters.java = function(callback)
                    jdtls:exec_cmd(
                        { command = "vscode.java.startDebugSession" },
                        { bufnr = vim.api.nvim_get_current_buf() },
                        function(err, port)
                            if err then
                                vim.notify("Failed to start debug session: " .. vim.inspect(err), vim.log.levels.ERROR)
                                return
                            end
                            callback({
                                type = "server",
                                host = "127.0.0.1",
                                port = port,
                            })
                        end
                    )
                end

                dap.configurations.java = {
                    {
                        type = "java",
                        request = "attach",
                        name = "Attach to Remote (port 5005)",
                        hostName = "127.0.0.1",
                        port = 5005,
                    },
                }

                jdtls:exec_cmd(
                    { command = "vscode.java.resolveMainClass" },
                    { bufnr = vim.api.nvim_get_current_buf() },
                    function(err, main_classes)
                        if err or not main_classes then
                            vim.notify("Could not resolve main classes", vim.log.levels.WARN)
                            return
                        end
                        for _, main in ipairs(main_classes) do
                            table.insert(dap.configurations.java, {
                                type = "java",
                                request = "launch",
                                name = "Launch " .. (main.mainClass or "Unknown"),
                                mainClass = main.mainClass,
                                projectName = main.projectName,
                            })
                        end
                        vim.notify("Java DAP configured: " .. #main_classes .. " main classes found", vim.log.levels.INFO)
                    end
                )
            end, 100)
        end, { desc = "Manually configure Java DAP adapter" })
    end,
}
