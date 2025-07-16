{ pkgs, ... }:

{
  # Set the default shell to zsh
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
}
