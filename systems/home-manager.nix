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
in
{
  pkgs = pkgs.legacyPackages.${system};

  modules =
    [
      # standard modules
      ../modules/home-manager/basic
      ../modules/home-manager/editor
      ../modules/home-manager/shell
      ../modules/home-manager/tools
      ../modules/home-manager/utilities

      # nix-index precompiled database
      inputs.nix-index-database.hmModules.nix-index

      # add extra arguments to modules
      {
        config._module.args = {
          inherit inputs username work;
        };
      }
    ]
    ++ pkgs.lib.optionals graphical [
      # standard graphical modules
      ../modules/home-manager/graphical
    ]
    ++ extraModules;
}
