{
  system,
  hostname,
  username,
  inputs,
  homeManagerConfiguration,
  extraModules ? [ ],
  graphical ? false,
  fat ? false,
  k8s ? false,
}:

let
  pkgs = inputs.nixpkgs;
  home-manager = inputs.home-manager;
in
{
  inherit system;

  modules =
    [
      # nix-index database so we don't have to build it on every system
      inputs.nix-index-database.nixosModules.nix-index

      # basic universal configurations
      ../modules/nixos/basic

      # home manager configuration
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;

        home-manager.users.${username}.imports = homeManagerConfiguration.modules;
      }

      # add extra arguments to modules
      {
        config._module.args = {
          inherit inputs hostname username;
        };
      }
    ]
    ++ pkgs.lib.optionals fat [
      # standard configurations
      ../modules/nixos/tools
    ]
    ++ pkgs.lib.optionals graphical [
      # default graphical configurations
      ../modules/nixos/graphical
    ]
    ++ pkgs.lib.optionals k8s [
      # set up k3s
      ../modules/nixos/k8s/k3s.nix
    ]
    ++ extraModules;
}
