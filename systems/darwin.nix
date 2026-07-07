{
  system,
  username,
  inputs,
  homeManagerConfiguration,
}:

let
  inherit (inputs) home-manager agenix;
in
{
  modules = [
    # basic configurations
    ../modules/nix-darwin/basic
    ../modules/nix-darwin/homebrew
    ../modules/nix-darwin/system

    # agenix
    agenix.darwinModules.default

    # home manager configuration
    home-manager.darwinModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        users.${username}.imports = homeManagerConfiguration.modules;
      };
    }

    # add extra arguments to modules
    {
      config._module.args = {
        inherit inputs username system;
      };
    }
  ];
}
