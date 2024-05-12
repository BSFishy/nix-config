{ pkgs, ... }:

{
  imports = [
    ./modules/shell.nix
    ./modules/utilities.nix
    ./modules/editor.nix
    ./modules/ui.nix
  ];

  xdg.enable = true;
  targets.genericLinux.enable = pkgs.stdenv.hostPlatform.isLinux;
}
