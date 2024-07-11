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
    programs.chromium = {
      enable = true;
      package = pkgs.google-chrome;
    };
  };
}
