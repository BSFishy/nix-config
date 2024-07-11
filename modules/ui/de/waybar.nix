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
    home.packages = [ pkgs.waybar ];

    xdg.configFile = {
      "waybar/config.jsonc".source = ./waybar/config.jsonc;
      "waybar/style.css".source = ./waybar/style.css;
    };
  };
}
