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
  options.distro.ui.browser.enable = lib.mkEnableOption "Browser installation";

  config = lib.mkIf (cfg.enable && cfg.browser.enable) {
    programs.chromium = {
      enable = true;
      package = pkgs.google-chrome;
      commandLineArgs = [ "--force-dark-mode" ];
    };
  };
}
