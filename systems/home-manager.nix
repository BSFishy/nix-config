{
  system,
  username,
  inputs,
  extraModules ? [ ],
  graphical ? false,
  work ? false,
}:

let
  pkgs = inputs.nixpkgs;
  agenix = inputs.agenix;
  overlay = import ../overlays;
in
{
  pkgs = (pkgs.legacyPackages.${system}).extend overlay;

  modules = [
    # codiff module definition (provides programs.codiff options)
    ../hm-modules/codiff.nix

    # standard modules
    ../modules/home-manager/basic
    ../modules/home-manager/editor
    ../modules/home-manager/shell
    ../modules/home-manager/tools
    ../modules/home-manager/utilities

    # nix-index precompiled database
    inputs.nix-index-database.homeModules.nix-index

    # agenix
    agenix.homeManagerModules.default

    # add extra arguments to modules
    {
      config._module.args = {
        inherit
          inputs
          username
          work
          system
          ;
        flakePkgs = inputs.self.packages.${system};
        llmPkgs = inputs.llm-agents.packages.${system};
      };
    }
  ]
  ++ pkgs.lib.optionals graphical [
    # ags shell
    inputs.ags.homeManagerModules.default

    # standard graphical modules
    ../modules/home-manager/graphical
  ]
  ++ extraModules;
}
