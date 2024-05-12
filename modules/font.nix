{ config, lib, pkgs, ... }:

let
  cfg = config.distro.graphics;
in
{
  options.distro.graphics.font = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable custom fonts";
    };
  };

  config = lib.mkIf cfg.enable {
    fonts.fontconfig.enable = cfg.font.enable;

    home.packages = lib.optionals cfg.font.enable [
      (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    ];
  };
}
