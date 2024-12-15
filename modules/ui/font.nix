{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.distro.ui;
  package = pkgs.nerd-fonts.jetbrains-mono;
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

    home.packages = [ package ];

    gtk.font = {
      package = package;
      name = "JetBrainsMonoNerdFont-Regular";
      size = 13;
    };
  };
}
