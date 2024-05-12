{ ... }:

{
  imports = [
    # Include command line tools
    ./server.nix

    # Install fonts
    ./modules/font.nix
  ];
}
