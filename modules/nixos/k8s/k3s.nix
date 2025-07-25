{ config, pkgs, ... }:

{
  # allow the port for local changes
  networking.firewall.allowedTCPPorts = [ 6443 ];

  # for longhorn
  environment.systemPackages = [ pkgs.nfs-utils ];
  services.openiscsi = {
    enable = true;
    name = "${config.networking.hostName}-initiatorhost";
  };

  services.k3s = {
    enable = true;
    clusterInit = true;
    gracefulNodeShutdown.enable = true;

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

    manifests = {
      metallb-frr.source = ./manifests/metallb-frr.yaml;
      metallb-config.source = ./manifests/metallb-config.yaml;

      # fix for longhorn paths
      longhorn-fix.source = ./manifests/longhorn-fix.yaml;
    };

    autoDeployCharts = {
      kyverno = {
        name = "kyverno";
        createNamespace = true;
        targetNamespace = "kyverno";
        repo = "https://kyverno.github.io/kyverno/";
        version = "3.4.4";
        hash = "sha256-Jz9gucK3BjSnA1pZGILk7DxCZN8461aLUm3KzXroAG4=";

        # TODO: i would really like this to be a yaml file
        values = import ./values/kyverno.nix { };
      };

      longhorn = {
        name = "longhorn";
        createNamespace = true;
        targetNamespace = "longhorn-system";
        repo = "https://charts.longhorn.io";
        version = "1.9.0";
        hash = "sha256-xQEQ3Od9EZnGxr2levfQpKgh3Qinet9xhiNM4twALtw=";

        # TODO: i would really like this to be a yaml file
        values = import ./values/longhorn.nix { };
      };
    };
  };
}
