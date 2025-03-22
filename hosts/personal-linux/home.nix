{ pkgs, ... }:

{
  # set basic home configuration
  home.username = "matt";
  home.homeDirectory = "/home/matt";

  # set home manager state version
  home.stateVersion = "24.11";

  # install a few basic packages for this system
  home.packages = [
    pkgs.xdg-utils
  ];

  # allow home manager to manage itself
  programs.home-manager.enable = true;

  # basic compatibility stuff
  xdg.enable = true;
  targets.genericLinux.enable = true;
}
