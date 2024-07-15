{ config, lib, ... }:

let
  cfg = config.distro.ui;
in
{
  config = lib.mkIf (cfg.enable && cfg.de.enable) {
    services.hyprpaper = {
      enable = true;

      settings = {
        preload = [ "${./wallpaper.jpeg}" ];

        wallpaper = [ ",${./wallpaper.jpeg}" ];
      };
    };
  };
}
