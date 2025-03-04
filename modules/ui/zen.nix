{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.distro.utilities;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  zen-flake = builtins.getFlake "github:0xc000022070/zen-browser-flake";
in
{
  config = lib.mkIf (cfg.enable && isLinux) {
    home.packages = [
      (config.lib.nixGL.wrap zen-flake.packages.${pkgs.system}.default)
    ];
  };
}
