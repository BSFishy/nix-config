{ lib, ... }:

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
  ];

  config = {
    targets.genericLinux.nixGL.defaultWrapper = lib.mkDefault "mesa";
  };
}
