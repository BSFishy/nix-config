{ lib, ... }:

{
  options.distro.ui.de.enable = lib.mkEnableOption "Desktop Environment configuration";

  imports = [
    ./de/hyprland.nix
    ./de/hyprpaper.nix
    ./de/hyprlock.nix
    ./de/waybar.nix
  ];
}
