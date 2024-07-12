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

alias cl="clear"
alias podman="sudo podman"
alias nix-shell="nix-shell --command zsh"

# Source .local_zshrc if it exists
if [ -f ~/.local_zshrc ]; then
    source ~/.local_zshrc
fi

