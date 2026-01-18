{ lib, pkgs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  config = lib.mkIf isLinux {
    programs.rofi = {
      enable = true;
      theme = "gruvbox-dark";
    };
  };
}
