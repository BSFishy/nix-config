{ lib, ... }:

{
  imports = [
    # Install a browser
    ./zen.nix

    # Install terminal emulator
    ./ghostty.nix
  ];

  config = {
    targets.genericLinux.nixGL.defaultWrapper = lib.mkDefault "mesa";
  };
}
