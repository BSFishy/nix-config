{
  username,
  inputs,
  homeManagerConfiguration,
}:

let
  home-manager = inputs.home-manager;
  agenix = inputs.agenix;
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
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;

      home-manager.users.${username}.imports = homeManagerConfiguration.modules;
    }

    # add extra arguments to modules
    {
      config._module.args = {
        inherit inputs username;
      };
    }
  ];
}
