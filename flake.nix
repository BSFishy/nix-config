{
  description = "My configurations for Home Manager and NixOS";

  inputs = {
    # universal flakes
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # flake utils
    flake-utils.url = "github:numtide/flake-utils";

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
      inputs.home-manager.follows = "home-manager";
    };

    # nix-index database so i dont have to build the database on every machine
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # secrets manager
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.darwin.follows = "nix-darwin";
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
      # nixos configuration for personal laptop
      orion-02-nixos = import ./systems/nixos.nix {
        inherit inputs;

        system = "x86_64-linux";
        hostname = "orion-02";
        username = "matt";
        extraModules = [
          # detected hardware configurations
          ./hosts/orion-02/hardware-configuration.nix

          # framework laptop hardware configurations
          nixos-hardware.nixosModules.framework-13-7040-amd
        ];

        homeManagerConfiguration = personal-linux-home-configuration {
          graphical = true;
        };

        graphical = true;
        fat = true;
      };

      # prometheus-01 server nixos configuration
      prometheus-01-nixos = import ./systems/nixos.nix {
        inherit inputs;

        system = "x86_64-linux";
        hostname = "prometheus-01";
        username = "matt";
        extraModules = [
          # extra host-specific configurations
          ./hosts/prometheus-01/configuration.nix

          # detected hardware configuration
          ./hosts/prometheus-01/hardware-configuration.nix

          # run ssh server
          ./modules/nixos/tools/ssh.nix

          # k8s server node
          ./modules/nixos/k8s/server.nix
        ];

        homeManagerConfiguration = personal-linux-home-configuration {
          graphical = false;
        };

        k8s = true;
      };

      # prometheus-02 server nixos configuration
      prometheus-02-nixos = import ./systems/nixos.nix {
        inherit inputs;

        system = "x86_64-linux";
        hostname = "prometheus-02";
        username = "matt";
        extraModules = [
          # extra host-specific configurations
          ./hosts/prometheus-02/configuration.nix

          # detected hardware configuration
          ./hosts/prometheus-02/hardware-configuration.nix

          # run ssh server
          ./modules/nixos/tools/ssh.nix

          # bootstrap k8s node
          ./modules/nixos/k8s/bootstrap.nix
        ];

        homeManagerConfiguration = personal-linux-home-configuration {
          graphical = false;
        };

        k8s = true;
      };

      # nix-darwin setup for my work mac
      work-darwin-configuration = import ./systems/darwin.nix {
        inherit inputs;

        username = "mprovost";
        homeManagerConfiguration = work-darwin-home-configuration;
      };

      personal-linux-home-configuration =
        {
          graphical,
        }:
        import ./systems/home-manager.nix {
          inherit inputs graphical;

          system = "x86_64-linux";
          username = "matt";
        };

      # home manager configuration for my work mac
      work-darwin-home-configuration = import ./systems/home-manager.nix {
        inherit inputs;

        system = "aarch64-darwin";
        username = "mprovost";

        graphical = true;
        work = true;
      };

      work-linux-home-configuration = import ./systems/home-manager.nix {
        inherit inputs;

        system = "x86_64-linux";
        username = "mprovost";

        work = true;
      };
    in
    {
      # nixos configurations
      nixosConfigurations = {
        orion-02 = nixpkgs.lib.nixosSystem orion-02-nixos;

        # servers
        prometheus-01 = nixpkgs.lib.nixosSystem prometheus-01-nixos;
        prometheus-02 = nixpkgs.lib.nixosSystem prometheus-02-nixos;
      };

      # the raw nix-darwin configurations
      rawDarwinConfigurations = {
        work-darwin = work-darwin-configuration;
      };

      # the home-manager configurations
      homeConfigurations = {
        work-linux = home-manager.lib.homeManagerConfiguration work-linux-home-configuration;
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
