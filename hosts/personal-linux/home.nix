{ pkgs, nixgl, ... }:

{
  # set basic home configuration
  home.username = "matt";
  home.homeDirectory = "/home/matt";

  # set home manager state version
  home.stateVersion = "24.11";

  # import modules for this configuration
  imports = [ ../../distro.nix ];

  # enable nixGL since this doesn't currently use nixos
  nixGL.packages = import nixgl { inherit pkgs; };

  # configure some the distro settings
  # FIXME: configuration should mostly be done by importing different files, not
  # like this
  distro = {
    ui = {
      enable = true;
      font.enable = true;
    };
  };

  # allow home manager to install and manage the nix commands
  home.packages = [
    pkgs.nix
  ];

  # allow home manager to manage itself
  programs.home-manager.enable = true;
}
