{ lib, ... }:

{
  options.distro.ui = {
    enable = lib.mkEnableOption "UI components";

    nixGLPrefix = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Will be prepended to commands which require working OpenGL.

        This needs to be set to the right nixGL package on non-NixOS systems.
      '';
    };
  };

  imports = [
    # Install fonts
    ./ui/font.nix

    # Install a browser
    ./ui/chrome.nix
    ./ui/zen.nix

    # Install terminal emulator
    ./ui/ghostty.nix
    ./ui/wezterm.nix
  ];

  config = {
    nixGL.defaultWrapper = lib.mkDefault "mesa";
  };
}
