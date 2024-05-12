{ pkgs, ... }:

{
  # TODO: install tmux config
  home.packages = [
    pkgs.tmux
  ];
}
