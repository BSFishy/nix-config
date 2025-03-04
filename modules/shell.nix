{ configurationName, ... }:

{

  home.sessionVariables = {
    HOME_MANAGER_CONFIG = configurationName;
  };

  imports = [
    # Set up shell related things
    ./shell/bash.nix
    ./shell/zsh.nix

    # Set up prompt
    ./shell/starship.nix
  ];
}
