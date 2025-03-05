{
  config,
  lib,
  pkgs,
  zen-flake,
  ...
}:

let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  config = lib.mkIf isLinux {
    home.packages = [
      (config.lib.nixGL.wrap zen-flake.packages.${pkgs.system}.default)
    ];
  };
}
