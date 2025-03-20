{ pkgs, ... }:

{
  # set basic home configuration
  home.username = "mprovost";
  home.homeDirectory = "/Users/mprovost";

  # set home manager state version
  home.stateVersion = "24.11";

  # allow home manager to install and manage the nix commands
  home.packages = [
    pkgs.nix
  ];

  # allow broken and unfree packages
  nixpkgs.config = {
    allowBroken = true;
    allowUnfree = true;
  };

  # allow home manager to manage itself
  programs.home-manager.enable = true;
}
