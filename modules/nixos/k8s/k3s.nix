{ ... }:

{
  # allow the port for local changes
  networking.firewall.allowedTCPPorts = [ 6443 ];

  services.k3s = {
    enable = true;
    clusterInit = true;

    extraFlags = [
      "--disable traefik"
      "--disable servicelb"
    ];

    manifests = {
      kube-vip.source = ./manifests/kube-vip.yaml;
      kube-vip-cloud-controller.source = ./manifests/kube-vip-cloud-controller.yaml;
    };
  };
}
