{ llmPkgs, ... }:

{
  imports = [
    ./pi-extensions.nix
  ];

  home.packages = [
    llmPkgs.pi
  ];

  home.file.".pi/agent/skills/documentation".source = ./skills/documentation;
}
