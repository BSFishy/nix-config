{ ... }:

{
  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # allow broken and unfree packages
  nixpkgs.config = {
    allowBroken = true;
    allowUnfree = true;
  };
}
