{  ... }:

{
  imports = [
    # Include command line tools
    ./server.nix

    # Include graphical options
    ./modules/nixGL.options.nix

    # Install fonts
    ./modules/font.nix

    # Install terminal emulator
    ./modules/wezterm.nix
  ];

  xdg.mime.enable = true;
}
