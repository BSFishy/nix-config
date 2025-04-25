{
  description = "My configurations for Home Manager and NixOS";

  inputs = {
    # universal flakes
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # flake utils
    flake-utils.url = "github:numtide/flake-utils";

    # don't currently use nixgl since im on nixos
    # nixgl = {
    #   url = "github:nix-community/nixGL";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # nix darwin latest
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
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
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      nix-darwin,
      nixos-hardware,
      home-manager,
      ...
    }@inputs:
    let
      # home manager modules that are used basically everywhere
      standard-home-modules = [
        ./modules/home-manager/editor
        ./modules/home-manager/shell
        ./modules/home-manager/tools
        ./modules/home-manager/utilities
      ];

      # nixos configuration for personal laptop
      personal-linux-nixos-configuration =
        let
          homeCfg = personal-linux-home-configuration;
        in
        {
          system = "x86_64-linux";
          modules = [
            # base configuration
            ./hosts/personal-linux/configuration.nix

            # hardware configuration
            nixos-hardware.nixosModules.framework-13-7040-amd

            # standard configurations
            ./modules/nixos/tools

            # home manager configuration
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.users.matt.imports = homeCfg.modules;
              home-manager.extraSpecialArgs = homeCfg.extraSpecialArgs;
            }
          ];
        };

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

          # add ghostty for terminfo
          ./modules/home-manager/ui/ghostty.nix
        ];

        extraSpecialArgs = {
          inherit inputs;
          configurationName = "server-linux";
        };
      };

      # nix-darwin setup for my work mac
      work-darwin-configuration =
        let
          homeCfg = work-darwin-home-configuration;
        in
        {
          modules = [
            # base configuration
            ./hosts/work-darwin/nix-darwin.nix

            # homebrew configuration
            ./modules/nix-darwin/homebrew
            ./modules/nix-darwin/system

            # home manager configuration
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.users.mprovost.imports = homeCfg.modules;
              home-manager.extraSpecialArgs = homeCfg.extraSpecialArgs;
            }
          ];

          specialArgs = {
            inherit inputs;
            configurationName = "work-darwin";
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
      # nixos configurations
      nixosConfigurations = {
        "personal-linux" = nixpkgs.lib.nixosSystem personal-linux-nixos-configuration;
      };

      # nix-darwin configurations
      darwinConfigurations = {
        "work-darwin" = nix-darwin.lib.darwinSystem work-darwin-configuration;
      };

      # the raw nix-darwin configurations
      rawDarwinConfigurations = {
        "work-darwin" = work-darwin-configuration;
      };

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
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.go
          ];
        };

        packages = rec {
          setup = pkgs.buildGoModule {
            pname = "setup";
            version = "0.1.0";
            src = ./setup;

            vendorHash = "sha256-HZDEbwXAoAiEINxWkGmMUzXWnGk0MQ8phwo4HSBmd0c=";
            nativeBuildInputs = [
              pkgs.makeWrapper
            ];

            buildInputs = [
              pkgs.git
              pkgs.nix
            ];

            postFixup = ''
              wrapProgram $out/bin/setup --prefix PATH : ${
                pkgs.lib.makeBinPath [
                  pkgs.git
                  pkgs.nix
                ]
              }
            '';
          };

          default = setup;
        };
      }
    );
}
