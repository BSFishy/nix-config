{ lib, ... }:

{
  options.distro.editor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable editor configuration";
    };
  };

  imports = [
    ./editor/tmux.nix
    ./editor/neovim.nix
  ];
}
