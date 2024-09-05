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

function CheckProjectFilesAndRun()
    if vim.fn.glob("*.go") ~= "" then
        -- Se encontró un archivo .go, ejecutar Go
        vim.cmd("lua vim.run_in_new_tab(\"air\")")
    else
        -- Se encontró pom.xml, ejecutar Maven
        Run_maven_test("mvn spring-boot:run", "mvn_start")
    end
end

-- Function to create a tmux new window with Maven command
function Run_maven_test(cmd, window_name)
    local green = "\27[38;2;166;227;161m" -- True color escape code for #a6e3a1
    local reset = "\27[0m"   -- ANSI escape code to reset text color
    local blank_lines = "\n\n\n" -- Three blank lines
    local full_cmd = "JAVA_HOME=~/.jdks/11.0.21 " .. cmd .. '; echo "' .. blank_lines
        .. green .. 'Press ENTER to close...' .. reset .. '"; read'
    local tmux_cmd = "tmux new-window -n " .. window_name .. " '" .. full_cmd .. "'"
    vim.fn.system(tmux_cmd)
end

-- Maven Test Class Normal
vim.api.nvim_set_keymap('n', '<Leader>mtc',
    ':lua Run_maven_test("mvn test -Dtest=" .. vim.fn.expand("%:t:r"), "mvn_test")<CR>',
    { noremap = true, silent = true })

-- Maven Test Class Debug
vim.api.nvim_set_keymap('n', '<Leader>mtd',
    ':lua Run_maven_test("mvn test -Dtest=" .. vim.fn.expand("%:t:r") .. " -Dmaven.surefire.debug", "mvn_debug")<CR>',
    { noremap = true, silent = true })

-- Maven Test Method Normal
vim.api.nvim_set_keymap('n', '<Leader>mtm',
    ':lua Run_maven_test(vim.fn.BuildMavenTestCommand(), "mvn_test_method")<CR>',
    { noremap = true, silent = true })

-- Maven Test Method Debug
vim.api.nvim_set_keymap('n', '<Leader>mmd',
    ':lua Run_maven_test(vim.fn.BuildMavenTestCommand() .. " -Dmaven.surefire.debug", "mvn_method_debug")<CR>',
    { noremap = true, silent = true })

-- Maven Clean Install
vim.api.nvim_set_keymap('n', '<Leader>ci',
    ':lua Run_maven_test("mvn clean install -DskipTests", "mvn_clean_install")<CR>',
    { noremap = true, silent = true })

-- Maven Start Normal
vim.api.nvim_set_keymap('n', '<Leader>msn', ':lua CheckProjectFilesAndRun()<CR>', { noremap = true, silent = true })

-- Map 'msd' to run the Maven debug command using the Run_maven_test function
vim.api.nvim_set_keymap('n', '<Leader>msd', [[:lua Run_maven_test('mvn spring-boot:run -Dspring-boot.run.jvmArguments=\\"-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005\\"', 'mvn_debug')<CR>]], { noremap = true, silent = true })

