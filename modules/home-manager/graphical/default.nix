{ lib, pkgs, ... }:

let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  imports = [
    # Install a browser
    ./zen.nix

    # Install terminal emulator
    ./ghostty.nix

    # Install app launcher
    ./rofi.nix

    # Install idle daemon
    ./hypridle.nix

    # Install lock screen
    ./hyprlock.nix

    # Configure hyprland
    ./hyprland.nix

    # Install ags shell
    ./ags.nix
  ];

  config = lib.mkIf isLinux {
    targets.genericLinux.nixGL.defaultWrapper = lib.mkDefault "mesa";

    home.packages = [ pkgs.obs-studio pkgs.chatterino7 pkgs.ungoogled-chromium ];
  };
}
