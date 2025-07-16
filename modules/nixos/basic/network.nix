{ hostname, ... }:

{
  networking.hostName = hostname; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;
}
