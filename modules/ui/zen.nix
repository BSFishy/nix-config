{
  config,
  lib,
  pkgs,
  zen-flake,
  ...
}:

let
  cfg = config.distro.utilities;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  config = lib.mkIf (cfg.enable && isLinux) {
    home.packages = [
      (config.lib.nixGL.wrap zen-flake.packages.${pkgs.system}.default)
    ];
  };
}
