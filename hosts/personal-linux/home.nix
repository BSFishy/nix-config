{ pkgs, inputs, ... }:

let
  nixgl = inputs.nixgl;
in
{
  # set basic home configuration
  home.username = "matt";
  home.homeDirectory = "/home/matt";

  # set home manager state version
  home.stateVersion = "24.11";

  # allow home manager to install and manage the nix commands
  home.packages = [
    pkgs.nix
    pkgs.xdg-utils
  ];

  # allow home manager to manage itself
  programs.home-manager.enable = true;

  # basic compatibility stuff
  xdg.enable = true;
  targets.genericLinux.enable = true;
}
