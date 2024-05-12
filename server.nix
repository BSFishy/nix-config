{ ... }:

{
  imports = [
    # Install shell tools
    ./modules/bash.nix
    ./modules/zsh.nix
    ./modules/direnv.nix
    ./modules/starship.nix

    # Install development tools
    ./modules/ssh.nix
    ./modules/git.nix
    ./modules/tmux.nix
    ./modules/neovim.nix
  ];

  xdg.enable = true;
  targets.genericLinux.enable = true;
}
