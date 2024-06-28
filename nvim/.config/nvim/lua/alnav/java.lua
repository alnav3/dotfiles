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
if vim.fn.has("win32") == 1 then
    -- utilizamos un file dentro del proyecto para saltarnos el limite de caracteres en la terminal
    -- Maven Start Normal
    vim.api.nvim_set_keymap('n', '<Leader>msn', ':call OpenJavaTerminalWithScrollback()<CR>', { noremap = true, silent = true })

    -- Maven Start Modo Debug
    vim.api.nvim_set_keymap('n', '<Leader>msd', ':lua vim.run_in_new_tab("java -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005 @dependencies")<CR>', { noremap = true, silent = true })

else
    -- Maven Start Normal
    vim.api.nvim_set_keymap('n', '<Leader>msn', ':lua CheckProjectFilesAndRun()<CR>', { noremap = true, silent = true })

    -- Maven Start Modo Debug
    vim.api.nvim_set_keymap('n', '<Leader>msd', ':lua vim.run_in_new_tab("mvn spring-boot:run -Dspring-boot.run.jvmArguments=\'-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005\'")<CR>', { noremap = true, silent = true })
end

function CheckProjectFilesAndRun()
    if vim.fn.glob("*.go") ~= "" then
        -- Se encontró un archivo .go, ejecutar Go
        vim.cmd("lua vim.run_in_new_tab(\"air\")")
    else
        -- Se encontró pom.xml, ejecutar Maven
        vim.cmd("lua vim.run_in_new_tab(\"mvn spring-boot:run\")")
    end
end

-- Maven Test Class Normal
--vim.api.nvim_set_keymap('n', '<Leader>mtc', ':lua vim.run_in_new_tab("mvn test -Dtest=" .. vim.fn.expand("%:t:r"))<CR>', { noremap = true, silent = true })

-- Maven Test Class Debug
vim.api.nvim_set_keymap('n', '<Leader>mtd', ':lua vim.run_in_new_tab("mvn test -Dtest=" .. vim.fn.expand("%:t:r") .. " -Dmaven.surefire.debug")<CR>', { noremap = true, silent = true })

-- Maven Test Method Normal
vim.api.nvim_set_keymap('n', '<Leader>mtm', ':lua vim.run_in_new_tab(vim.fn.BuildMavenTestCommand())<CR>', { noremap = true, silent = true })

-- Maven Test Method Debug
vim.api.nvim_set_keymap('n', '<Leader>mmd', ':lua vim.run_in_new_tab("mvn test -Dtest=" .. vim.fn.BuildMavenTestCommand() .. " -Dmaven.surefire.debug")<CR>', { noremap = true, silent = true })

-- Maven Clean Install
vim.api.nvim_set_keymap('n', '<Leader>ci', ':lua vim.run_in_new_tab("mvn clean install -DskipTests")<CR>', { noremap = true, silent = true })


