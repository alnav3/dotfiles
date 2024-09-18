{config, pkgs, ... }:

let
  additionalJDKs = with pkgs; [ temurin-bin-11 temurin-bin-17 ];
in
{
  home.username = "alnav";
  home.stateVersion = "24.05";
  home.homeDirectory = "/home/alnav";
  programs.home-manager.enable = true;


  home.sessionPath = [
    "$HOME/.local/share/nvim/mason/bin"
    "$HOME/.local/share/nvim/mason/packages/lua-language-server/libexec/lib"
    "$HOME/.jdks"
  ];
  home.file = (builtins.listToAttrs (builtins.map (jdk: {
    name = ".jdks/${jdk.version}";
    value = { source = jdk; };
  }) additionalJDKs));
}
