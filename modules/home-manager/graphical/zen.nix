{
  config,
  lib,
  pkgs,
  inputs,
  system,
  ...
}:

let
  zen-flake = inputs.zen-flake;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  config = lib.mkIf isLinux {
    home.packages = [
      (config.lib.nixGL.wrap zen-flake.packages.${system}.default)
    ];
  };
}
