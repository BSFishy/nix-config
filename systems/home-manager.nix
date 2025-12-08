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
in
{
  pkgs = pkgs.legacyPackages.${system};

  modules = [
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
      };
    }
  ]
  ++ pkgs.lib.optionals graphical [
    # standard graphical modules
    ../modules/home-manager/graphical
  ]
  ++ extraModules;
}
