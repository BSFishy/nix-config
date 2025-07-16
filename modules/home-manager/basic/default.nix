{ ... }:

{
  imports = [
    ./linux.nix
    ./nix.nix
    ./user.nix
  ];

  # set home manager state version
  home.stateVersion = "24.11";

  # allow home manager to manage itself
  programs.home-manager.enable = true;
}
