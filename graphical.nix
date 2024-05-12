{ ... }:

{
  imports = [
    # Include command line tools
    ./server.nix

    # Install fonts
    ./modules/font.nix

    # Install terminal emulator
    ./modules/wezterm.nix
  ];
}
