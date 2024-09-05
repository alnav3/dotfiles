function welcome_message() {
    echo -e " ____  _     _      ____  _    "
    echo -e "/  _ \/ \   / \  /|/  _ \/ \ |\\"
    echo -e "| / \|| |   | |\ ||| / \|| | //"
    echo -e "| |-||| |_/\| | \||| |-||| \// "
    echo -e "\_/ \|\____/\_/  \|\_/ \|\__/"
}
welcome_message
source ~/.nix-profile/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.nix-profile/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
source ~/.nix-profile/share/zsh-fzf-history-search/zsh-fzf-history-search.plugin.zsh

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/zen.toml)"
fi

eval "$(zoxide init --cmd cd zsh)"
export EDITOR=nvim
export VISUAL=nvim
export XDG_CONFIG_HOME=$HOME/.config
export JAVA_HOME=~/.jdks/17.0.9
export NIX_LD=/nix/store/r8qsxm85rlxzdac7988psm7gimg4dl3q-glibc-2.39-52/lib/ld-linux-x86-64.so.2
export NIX_LD_LIBRARY_PATH=/nix/store/qksd2mz9f5iasbsh398akdb58fx9kx6d-gcc-13.2.0-lib/lib:/nix/store/mg1284kfh1m2xms1ghsw4nv8vhqisj22-openssl-3.0.14/lib

alias cl="clear"
alias k="kubectl"
alias nix-shell="nix-shell --command zsh"
alias mvn="JAVA_HOME=~/.jdks/11.0.21 mvn"

# Source .local_zshrc if it exists
if [ -f ~/.local_zshrc ]; then
    source ~/.local_zshrc
fi

