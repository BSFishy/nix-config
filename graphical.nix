{ pkgs, ... }:

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

  home.packages = [
    pkgs.mesa pkgs.libGL
  ];

  xdg.mime.enable = true;
}
