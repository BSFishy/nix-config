{ inputs, lib, pkgs, ... }:

let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  config = lib.mkIf isLinux {
    programs.ags = {
      enable = true;

      configDir = ./ags;

      extraPackages = [
        inputs.astal.packages.${pkgs.stdenv.system}.battery
        inputs.astal.packages.${pkgs.stdenv.system}.powerprofiles
      ];
    };
  };
}
