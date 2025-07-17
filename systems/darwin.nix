{
  username,
  inputs,
  homeManagerConfiguration,
}:

let
  home-manager = inputs.home-manager;
in
{
  modules = [
    # basic configurations
    ../modules/nix-darwin/basic
    ../modules/nix-darwin/homebrew
    ../modules/nix-darwin/system

    # home manager configuration
    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;

      home-manager.users.${username}.imports =
        builtins.trace homeManagerConfiguration.modules homeManagerConfiguration.modules;
    }

    # add extra arguments to modules
    {
      config._module.args = {
        inherit inputs;
      };
    }
  ];
}
