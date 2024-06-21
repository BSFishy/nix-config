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
  options.distro.ui.font = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable custom fonts";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.font.enable) {
    fonts.fontconfig.enable = true;

    home.packages = [ (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; }) ];
  };
}
