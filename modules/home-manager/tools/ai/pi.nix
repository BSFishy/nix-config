{ llmPkgs, ... }:

{
  imports = [
    ./pi-extensions.nix
  ];

  home.packages = [
    llmPkgs.pi
  ];

  home.file.".pi/agent/skills/documentation".source = ./skills/documentation;
  home.file.".pi/agent/skills/command-not-found".source = ./skills/command-not-found;
}
