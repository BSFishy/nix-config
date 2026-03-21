_:

{
  imports = [
    ./boot.nix
    ./locale.nix
    ./network.nix
    ./nix.nix
    ./nix-ld.nix
    ./shell.nix
    ./user.nix
  ];

  system.stateVersion = "23.11";
}
