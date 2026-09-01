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
  home.file.".pi/agent/skills/ship".source = ./skills/ship;
  home.file.".pi/agent/skills/fetch-project".source = ./skills/fetch-project;

  home.file.".pi/agent/prompts/catalog.md".source = ./commands/catalog.md;
  home.file.".pi/agent/prompts/learn.md".source = ./commands/learn.md;
  home.file.".pi/agent/prompts/ship.md".source = ./commands/ship.md;
}
