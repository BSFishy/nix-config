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
      "--disable coredns"
    ];

    manifests = {
      kube-vip.source = ./manifests/kube-vip.yaml;
      kube-vip-cloud-controller.source = ./manifests/kube-vip-cloud-controller.yaml;

      # fix for longhorn paths
      longhorn-fix.source = ./manifests/longhorn-fix.yaml;
    };

    autoDeployCharts = {
      longhorn = {
        name = "longhorn";
        createNamespace = true;
        targetNamespace = "longhorn-system";
        repo = "https://charts.longhorn.io";
        version = "1.9.0";
        hash = "sha256-xQEQ3Od9EZnGxr2levfQpKgh3Qinet9xhiNM4twALtw=";

        # TODO: i would really like this to be a yaml file
        values = import ./longhorn.nix { };
      };
    };
  };
}
