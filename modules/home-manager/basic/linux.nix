{ lib, pkgs, ... }:

let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  config = lib.mkIf isLinux {
    # install a few basic packages for this system
    home.packages = [
      pkgs.xdg-utils
    ];

    # basic compatibility stuff
    xdg.enable = true;
    targets.genericLinux.enable = true;
  };
}
