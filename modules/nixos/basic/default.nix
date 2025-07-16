{ ... }:

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
}
