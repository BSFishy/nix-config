{ config, lib, pkgs, ... }:

let
  nixGL = import ./nixGL.nix { inherit pkgs config; };
  cfg = config.distro.graphics;
in
{
  config = lib.mkIf cfg.enable {
    programs.wezterm = {
      enable = true;
      enableZshIntegration = true;

      package = (nixGL pkgs.wezterm);

      extraConfig = builtins.readFile ./wezterm.lua;
    };
  };
}
