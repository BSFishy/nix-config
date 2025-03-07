{
  description = "My configurations for Home Manager and NixOS";

  inputs = {
    # universal flakes
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home manager latest
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # zen browser
    # only using this while there isnt a zen package in nixpkgs
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
    { nixpkgs, home-manager, ... }@inputs:
    let
      # home manager modules that are used basically everywhere
      standard-home-modules = [
        ./modules/home-manager/editor
        ./modules/home-manager/shell
        ./modules/home-manager/utilities
      ];

      # home manager configuration for graphical personal linux machines
      personal-linux-home-configuration = {
        pkgs = nixpkgs.legacyPackages."x86_64-linux";

        modules = standard-home-modules ++ [
          # base configuration
          ./hosts/personal-linux/home.nix

          # graphical programs
          ./modules/home-manager/ui
        ];

        extraSpecialArgs = {
          inherit inputs;
          configurationName = "personal-linux";
        };
      };

      # home manager configuration for linux machines without graphical
      # environments
      server-linux-home-configuration = {
        pkgs = nixpkgs.legacyPackages."x86_64-linux";

        modules = standard-home-modules ++ [
          # base configuration
          ./hosts/server-linux/home.nix
        ];

        extraSpecialArgs = {
          inherit inputs;
          configurationName = "server-linux";
        };
      };

      # home manager configuration for my work mac
      work-darwin-home-configuration = {
        pkgs = nixpkgs.legacyPackages."aarch64-darwin";

        modules = standard-home-modules ++ [
          # base configuration
          ./hosts/work-darwin/home.nix

          # graphical programs
          ./modules/home-manager/ui
        ];

        extraSpecialArgs = {
          inherit inputs;
          configurationName = "work-darwin";
        };
      };
    in
    {
      # home manager configurations
      homeConfigurations = {
        "personal-linux" = home-manager.lib.homeManagerConfiguration personal-linux-home-configuration;
        "server-linux" = home-manager.lib.homeManagerConfiguration server-linux-home-configuration;
        "work-darwin" = home-manager.lib.homeManagerConfiguration work-darwin-home-configuration;
      };

      # the raw home manager configurations. useful for my work setup, where i
      # use a separate flake to futher configure my home manager setup
      rawHomeConfigurations = {
        "personal-linux" = personal-linux-home-configuration;
        "server-linux" = server-linux-home-configuration;
        "work-darwin" = work-darwin-home-configuration;
      };
    };
}
