# Installation

Installation on a fresh system involves a few steps. This guide offers the steps
to go from zero to fully setup.

## Nix

Nix can be installed through the official Nix installer, however I've come to prefer
the [Determinate Systems Nix installer](https://github.com/DeterminateSystems/nix-installer).
It offers a few main benefits, mainly enabling flakes and the unified command by
default. Here is the command to install Nix:

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

## Home Manager

Home Manager is the main thing needed to use this config. Here are the commands
to install Home Manager:

```sh
# add the home manager channel & nixGL channel if needed
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
# nix-channel --add https://github.com/nix-community/nixGL/archive/main.tar.gz nixgl
nix-channel --update

# install home manager
nix-shell '<home-manager>' -A install
```

## Clone the Git repository

Since Home Manager adds a `~/.config/home-manager` directory and a `home.nix` file
into that directory, you can't simply clone into that directory. Instead, you need
to initialize the repository then pull the data. Here are the commands for that:

```sh
# move into the directory
cd ~/.config/home-manager

# initialize the directory with the repository
git init
git remote add origin git@github.com:BSFishy/home.nix.git
git fetch

# restore the files
git reset origin/main
git checkout -t origin/main
```

## Apply the configuration

Finally, it is time to apply the configuration:

```sh
# add the imports = [ ./distro.nix ]; to the file
nano distro.nix

# apply the config
home-manager switch -b backup
```
