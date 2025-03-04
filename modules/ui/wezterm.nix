{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.distro.ui;
in
{
  config = lib.mkIf cfg.enable {
    programs.wezterm = {
      enable = true;
      enableZshIntegration = true;

      package = config.lib.nixGL.wrap pkgs.wezterm;

      extraConfig = builtins.readFile ./wezterm.lua;
    };
  };
}
