{ config, pkgs, ... }:

{
  # allow ingress for required k3s communications
  networking.firewall = {
    allowedTCPPorts = [
      179
      6443
      10250
      5001
      2379
      2380
    ];

    allowedUDPPorts = [
      8472
      51820
      51821
    ];
  };

  # for longhorn
  environment.systemPackages = [ pkgs.nfs-utils ];
  services.openiscsi = {
    enable = true;
    name = "${config.networking.hostName}-initiatorhost";
  };

  services.k3s = {
    enable = true;
    gracefulNodeShutdown.enable = true;
  };
}
