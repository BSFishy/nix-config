{ pkgs, ... }:

{
  imports = [
    ./linux.nix
    ./nix.nix
    ./user.nix
  ];

  # add ghostty terminfo so everyone understands the terminal features
  home.packages = [
    pkgs.ghostty.terminfo
  ];

  # set home manager state version
  home.stateVersion = "24.11";

  # allow home manager to manage itself
  programs.home-manager.enable = true;
}
