{ pkgs, ... }:

let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  imports = [
    ./modules/shell.nix
    ./modules/utilities.nix
    ./modules/editor.nix
    ./modules/ui.nix
  ];

  xdg.enable = isLinux;
  targets.genericLinux.enable = isLinux;
}
