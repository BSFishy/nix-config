{ config, pkgs, ... }:

{
  # allow ingress for required k3s communications
  networking.firewall = {
    allowedTCPPorts = [
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

  age.secrets.k3s-token.file = ../../../secrets/k3s-token.age;

  services.k3s = {
    enable = true;
    gracefulNodeShutdown.enable = true;
    tokenFile = config.age.secrets.k3s-token.path;

    extraFlags = [
      "--disable traefik"
      "--disable servicelb"

      # cluster controlplane configuration
      "--tls-san=k8s.mattprovost.dev"

      # dual stack
      "--cluster-cidr 10.42.0.0/16,fd42:abcd:1234::/48"
      "--flannel-ipv6-masq"
      "--service-cidr 10.43.0.0/16,fd42:abcd:1234:1::/112"
    ];
  };
}
