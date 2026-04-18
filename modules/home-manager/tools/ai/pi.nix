{ llmPkgs, ... }:

{
  imports = [
    ./pi-extensions.nix
  ];

  home.packages = [
    llmPkgs.pi
  ];
}
