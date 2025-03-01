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
    programs.ghostty = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;

      package = config.lib.nixGL.wrap pkgs.ghostty;

      settings = {
        theme = "GruvboxDark";
        font-size = 13;
        adjust-font-baseline = "20%";
      };
    };
  };
}
