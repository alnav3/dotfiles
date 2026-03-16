vim.cmd([[
function! GetFullClassName()
    if has("unix")
        return substitute(fnamemodify(substitute(substitute(expand('%:p'), getcwd() . "/", "", ""), 'src/test/java/', '', ''), ':r'), "/", ".", "g")
    else
        return substitute(fnamemodify(substitute(substitute(substitute(expand('%:p'), '\\', '/', 'g'), substitute(getcwd(), '\\', '/', 'g') . "/", "", ""), 'src/test/java/', '', ''), ':r'), "/", ".", "g")
    endif
endfunction

function! GetJavaMethodName()
    " Busca hacia atrás la primera línea que parece una definición de método
    let l:method_line = search('^\s*\(public\|private\|protected\|static\)\s\+\w\+\s\+\(\w\+\)\s*(', 'bn')
    " Si encontramos una línea que coincide
    if l:method_line != 0
        " Extrae el nombre del método
        let l:method_name = matchstr(getline(l:method_line), '\w\+\ze\s*(')
        return l:method_name
    endif
    return ""
endfunction

function! BuildMavenTestCommand()
    let l:full_class_name = GetFullClassName()
    let l:method_name = GetJavaMethodName()
    return "mvn test -Dtest=" . l:full_class_name . "\\#" . l:method_name
endfunction

function! GetPackageName()
let l:path = substitute(fnamemodify(expand('%:p'), ':.'), '\', '/', 'g')
let l:mainPath = substitute(getcwd(), '\', '/', 'g') . "/src/main/java/"
let l:testPath = substitute(getcwd(), '\', '/', 'g') . "/src/test/java/"

if stridx(l:path, l:mainPath) == 0
    return substitute(l:path[len(l:mainPath):], '/', '.', 'g')
elseif stridx(l:path, l:testPath) == 0
    return substitute(l:path[len(l:testPath):], '/', '.', 'g')
    endif
    return ""
    endfunction
]])

-- Build tool detection
function DetectBuildTool()
    local cwd = vim.fn.getcwd()
    if vim.fn.filereadable(cwd .. "/build.gradle") == 1 or vim.fn.filereadable(cwd .. "/build.gradle.kts") == 1 or vim.fn.filereadable(cwd .. "/settings.gradle") == 1 then
        return "gradle"
    elseif vim.fn.filereadable(cwd .. "/pom.xml") == 1 then
        return "maven"
    end
    return nil
end

-- Get the gradle wrapper or fallback to gradle command
function GetGradleCommand()
    local cwd = vim.fn.getcwd()
    if vim.fn.filereadable(cwd .. "/gradlew") == 1 then
        return "./gradlew"
    end
    return "gradle"
end

-- Read JVM args from ~/.gradle-jvm-args if it exists
-- Returns empty string if file doesn't exist
function GetGradleJvmArgs()
    local args_file = vim.fn.expand("~/.gradle-jvm-args")
    if vim.fn.filereadable(args_file) == 1 then
        local lines = vim.fn.readfile(args_file)
        local args = {}
        for _, line in ipairs(lines) do
            -- Skip empty lines and comments
            line = vim.fn.trim(line)
            if line ~= "" and not vim.startswith(line, "#") then
                table.insert(args, line)
            end
        end
        if #args > 0 then
            return table.concat(args, " ")
        end
    end
    return ""
end

-- Build the JAVA_TOOL_OPTIONS prefix if gradle args file exists
function GetGradleEnvPrefix()
    local jvm_args = GetGradleJvmArgs()
    if jvm_args ~= "" then
        -- Use double quotes and escape any special chars
        -- (the args typically don't contain $ or " so this is safe)
        jvm_args = jvm_args:gsub('\\', '\\\\'):gsub('"', '\\"')
        return 'JAVA_TOOL_OPTIONS="' .. jvm_args .. '" '
    end
    return ""
end

-- Build Gradle test command for class
function BuildGradleTestClassCommand(class_name)
    return GetGradleCommand() .. " test --tests \"" .. class_name .. "\""
end

-- Build Gradle test command for method
function BuildGradleTestMethodCommand()
    local full_class_name = vim.fn.GetFullClassName()
    local method_name = vim.fn.GetJavaMethodName()
    return GetGradleCommand() .. " test --tests \"" .. full_class_name .. "." .. method_name .. "\""
end

-- Función auxiliar para ejecutar comandos en una nueva pestaña de terminal
vim.run_in_new_tab = function(command)
    vim.cmd('tabnew') -- abre una nueva pestaña
    vim.cmd('term ' .. command) -- ejecuta el comando en un terminal en esa pestaña
    vim.cmd('setlocal scrollback=-1')
end

-- Definición de la función BuildMavenTestCommand en Vimscript
vim.cmd([[
function! BuildMavenTestCommand()
    let l:full_class_name = GetFullClassName()
    let l:method_name = GetJavaMethodName()
    return "mvn test -Dtest=" . l:full_class_name . "\\#" . l:method_name
endfunction
]])

vim.cmd([[
function! OpenJavaTerminalWithScrollback()
    " Abre la terminal en una nueva pestaña
    tabnew | term java @dependencies

    " Establece scrollback para esta terminal
    setlocal scrollback=-1
endfunction

]])

function StartOpenCode()
    vim.fn.system("tmux new-window -n opencode 'opencode'")
end

function CheckProjectFilesAndRun()
    if vim.fn.glob("*.go") ~= "" then
        -- Go project found
        vim.fn.system("tmux new-window -n go_run 'air'")
    else
        local build_tool = DetectBuildTool()
        if build_tool == "gradle" then
            local env_prefix = GetGradleEnvPrefix()
            Run_java_command(env_prefix .. GetGradleCommand() .. " bootRun", "gradle_start")
        else
            -- Default to Maven
            Run_java_command("mvn spring-boot:run", "mvn_start")
        end
    end
end

-- Function to create a tmux new window with build command
function Run_java_command(cmd, window_name)
    local green = "\27[38;2;166;227;161m" -- True color escape code for #a6e3a1
    local reset = "\27[0m"   -- ANSI escape code to reset text color
    local blank_lines = "\n\n\n" -- Three blank lines
    local full_cmd = "JAVA_HOME=~/.jdks/21.0.8 " .. cmd .. '; echo "' .. blank_lines
        .. green .. 'Press ENTER to close...' .. reset .. '"; read'
    local tmux_cmd = "tmux new-window -n " .. window_name .. " '" .. full_cmd .. "'"
    vim.fn.system(tmux_cmd)
end

-- Unified test class command
function TestClass()
    local build_tool = DetectBuildTool()
    local class_name = vim.fn.expand("%:t:r")
    if build_tool == "gradle" then
        Run_java_command(BuildGradleTestClassCommand(class_name), "gradle_test")
    else
        Run_java_command("mvn test -Dtest=" .. class_name, "mvn_test")
    end
end

-- Unified test class debug command
function TestClassDebug()
    local build_tool = DetectBuildTool()
    local class_name = vim.fn.expand("%:t:r")
    if build_tool == "gradle" then
        Run_java_command(BuildGradleTestClassCommand(class_name) .. " --debug-jvm", "gradle_debug")
    else
        Run_java_command("mvn test -Dtest=" .. class_name .. " -Dmaven.surefire.debug", "mvn_debug")
    end
end

-- Unified test method command
function TestMethod()
    local build_tool = DetectBuildTool()
    if build_tool == "gradle" then
        Run_java_command(BuildGradleTestMethodCommand(), "gradle_test_method")
    else
        Run_java_command(vim.fn.BuildMavenTestCommand(), "mvn_test_method")
    end
end

-- Unified test method debug command
function TestMethodDebug()
    local build_tool = DetectBuildTool()
    if build_tool == "gradle" then
        Run_java_command(BuildGradleTestMethodCommand() .. " --debug-jvm", "gradle_method_debug")
    else
        Run_java_command(vim.fn.BuildMavenTestCommand() .. " -Dmaven.surefire.debug", "mvn_method_debug")
    end
end

-- Unified clean build command
function CleanBuild()
    local build_tool = DetectBuildTool()
    if build_tool == "gradle" then
        Run_java_command(GetGradleCommand() .. " clean build -x test", "gradle_build")
    else
        Run_java_command("mvn clean install -DskipTests", "mvn_clean_install")
    end
end

-- Unified start with debug command
function StartDebug()
    local build_tool = DetectBuildTool()
    if build_tool == "gradle" then
        local env_prefix = GetGradleEnvPrefix()
        Run_java_command(env_prefix .. GetGradleCommand() .. " bootRun --debug-jvm", "gradle_debug")
    else
        Run_java_command('mvn spring-boot:run -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005"', "mvn_debug")
    end
end

-- Keep Run_maven_test as alias for backwards compatibility
Run_maven_test = Run_java_command

-- Test Class Normal (works for both Maven and Gradle)
vim.api.nvim_set_keymap('n', '<Leader>mtc', ':lua TestClass()<CR>', { noremap = true, silent = true })

-- Test Class Debug (works for both Maven and Gradle)
vim.api.nvim_set_keymap('n', '<Leader>mtd', ':lua TestClassDebug()<CR>', { noremap = true, silent = true })

-- Test Method Normal (works for both Maven and Gradle)
vim.api.nvim_set_keymap('n', '<Leader>mtm', ':lua TestMethod()<CR>', { noremap = true, silent = true })

-- Test Method Debug (works for both Maven and Gradle)
vim.api.nvim_set_keymap('n', '<Leader>mmd', ':lua TestMethodDebug()<CR>', { noremap = true, silent = true })

-- Clean Build (works for both Maven and Gradle)
vim.api.nvim_set_keymap('n', '<Leader>ci', ':lua CleanBuild()<CR>', { noremap = true, silent = true })

-- Start App Normal (works for Go, Maven, and Gradle)
vim.api.nvim_set_keymap('n', '<Leader>msn', ':lua CheckProjectFilesAndRun()<CR>', { noremap = true, silent = true })

-- start opencode in the folder
vim.api.nvim_set_keymap('n', '<Leader>ai', ':lua StartOpenCode()<CR>', { noremap = true, silent = true })

-- Start App Debug (works for both Maven and Gradle)
vim.api.nvim_set_keymap('n', '<Leader>msd', ':lua StartDebug()<CR>', { noremap = true, silent = true })

