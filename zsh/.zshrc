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

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/zen.toml)"
fi

eval "$(zoxide init --cmd cd zsh)"
export EDITOR=nvim
export VISUAL=nvim
export XDG_CONFIG_HOME=$HOME/.config

alias cl="clear"
alias podman="sudo podman"
