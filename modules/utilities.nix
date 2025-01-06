{ lib, ... }:

{
  options.distro.utilities = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable utilities configuration";
    };
  };

  imports = [
    ./utilities/chimera.nix
    ./utilities/xdg.nix
    ./utilities/direnv.nix
    ./utilities/ssh.nix
    ./utilities/git.nix
    ./utilities/nixfmt.nix
  ];
}
