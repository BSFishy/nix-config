{ lib, pkgs, ... }:

let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  imports = [
    ./boot.nix
    ./locale.nix
    ./network.nix
    ./nix.nix
    ./shell.nix
    ./user.nix
  ];

  system.stateVersion = "23.11";

  config = lib.mkIf isLinux {
    programs.nix-ld = {
      enable = true;
      libraries = [
        pkgs.stdenv.cc.cc
        pkgs.zlib
        pkgs.fuse3
        pkgs.icu
        pkgs.nss
        pkgs.openssl
        pkgs.curl
        pkgs.expat
      ];
    };
  };
}
