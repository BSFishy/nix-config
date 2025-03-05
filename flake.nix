{
  description = "My configurations for Home Manager and NixOS";

  inputs = {
    # universal flakes
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # flake utils
    flake-utils.url = "github:numtide/flake-utils";

    # home manager latest
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # zen browser
    zen-flake = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # chimera lxc front end
    chimera-flake = {
      url = "github:BSFishy/chimera";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixgl,
      home-manager,
      flake-utils,
      zen-flake,
      chimera-flake,
      ...
    }:
    flake-utils.lib.eachDefaultSystemPassThrough (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        homeConfigurations = {
          "personal-linux" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;

            modules = [
              # base configuration
              ./hosts/personal-linux/home.nix

              # environment configuration
              ./modules/home-manager/editor
              ./modules/home-manager/shell
              ./modules/home-manager/ui
              ./modules/home-manager/utilities
            ];

            extraSpecialArgs = {
              inherit nixgl zen-flake chimera-flake;
              configurationName = "personal-linux";
            };
          };

          "work-darwin" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;

            modules = [
              # base configuration
              ./hosts/work-darwin/home.nix

              # environment configuration
              ./modules/home-manager/editor
              ./modules/home-manager/shell
              ./modules/home-manager/ui
              ./modules/home-manager/utilities
            ];

            extraSpecialArgs = {
              configurationName = "work-darwin";
            };
          };
        };
      }
    );
}
