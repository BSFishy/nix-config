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
To enable modules, import them in the `home.nix` file.
For example, to enable the `graphical.nix`, your `home.nix` file might look like this:

```nix
{ config, pkgs, ... }:

{
  home.username = "jdoe";
  home.homeDirectory = "/home/jdoe";

  home.stateVersion = "23.11";

  imports = [ ./graphical.nix ];

  programs.home-manager.enable = true;
}
```

After you enable the modules you want, you can run `home-manager switch` to apply the changes.

### Graphical Environment

If on a non-NixOS system, you will most likely need to set up [NixGL](https://github.com/nix-community/nixGL).
This will involve adding the proper channel:

```shell
nix-channel --add https://github.com/nix-community/nixGL/archive/main.tar.gz nixgl && nix-channel --update
```

Then adding the `nixGLPrefix` to your `home.nix` file.
You can use whichever nixGL command you want, but a good starting point is the auto default:

```nix
{
  nixGLPrefix = "${(import <nixgl> {}).auto.nixGLDefault}/bin/nixGL";
}
```

## Modules

There are some top-level modules that are meant to be the main entry points for the configuration.
These are for specific environments, for example graphical or server.
Submodules live in the [`modules`](./modules) directory and can be used directly if desired.

| Name                               | Description                                                                                             |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------- |
| [`graphical.nix`](./graphical.nix) | Configuration for graphical environments. Imports `server.nix` for command line and related tools.      |
| [`server.nix`](./server.nix)       | Configuration for server environments. Primarily command line, shell, and prompt related configuration. |
