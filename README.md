# home.nix

This is my [home-manager](https://github.com/nix-community/home-manager) configuration.
This is how I configure my user environment on \*nix systems.
I have set it up in a modular format so that I can pick and choose which modules I want to use on a per-machine basis.

## Installation

First, [Nix](https://nixos.org/download.html) and [home-manager](https://github.com/nix-community/home-manager#installation) must be installed.
After that, this command can be run to clone the repository:

```shell
git clone git@github.com:BSFishy/home.nix.git ~/.config/home-manager
```

This will add the modules to the home-manager configuration.
To enable modules, import `distro.nix` in the `home.nix` file:

```nix
{ config, pkgs, ... }:

{
  home.username = "jdoe";
  home.homeDirectory = "/home/jdoe";

  home.stateVersion = "23.11";

  imports = [ ./distro.nix ];

  programs.home-manager.enable = true;
}
```

After you enable the modules you want, you can run `home-manager switch` to apply the changes.

### Configuration

These modules are configured through home configuration.
The main configuration root is `distro`.
For example, you can enable the graphical aspects with something like this:

```nix
{
  distro = {
    ui = {
      enable = true;

      # Typically necessary for non-NixOS systems
      nixGLPrefix = "${(import <nixgl> {}).auto.nixGLDefault}/bin/nixGL";
    };
  };
}
```

On non-NixOS systems, [NixGL](https://github.com/nix-community/nixGL) is typically necessary for graphical applications to work.
The previous example has a NixGL prefix set as an example, but the channel will also need to be added:

```shell
nix-channel --add https://github.com/nix-community/nixGL/archive/main.tar.gz nixgl && nix-channel --update
```

Some common (default) configuration options are:

```nix
{
  distro = {
    # Utilities such as git, ssh, direnv, etc.
    utilities.enable = true;

    # Editor setup (tmux & neovim)
    editor.enable = true;

    # Interface setup for fonts, programs, etc.
    ui.enable = false;
  };
}
```
