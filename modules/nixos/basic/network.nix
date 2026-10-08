{ hostname, ... }:

{
  networking.hostName = hostname; # Define your hostname.

  # Enable networking and check for captive portals using NetworkManager's
  # standard connectivity endpoint.
  networking.networkmanager = {
    enable = true;
    settings.connectivity = {
      uri = "http://nmcheck.gnome.org/check_network_status.txt";
      response = "NetworkManager is online";
      interval = 300;
    };
  };
}
