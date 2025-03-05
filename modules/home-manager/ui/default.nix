{ lib, ... }:

{
  imports = [
    # Install a browser
    ./zen.nix

    # Install terminal emulator
    ./ghostty.nix
    ./wezterm.nix
  ];

  config = {
    nixGL.defaultWrapper = lib.mkDefault "mesa";
  };
}
