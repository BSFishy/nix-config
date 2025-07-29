{ ... }:

{
  services.k3s = {
    clusterInit = true;

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
      # distributed storage
      kyverno-chart.source = ./manifests/kyverno-chart.yaml;
      longhorn-chart.source = ./manifests/longhorn-chart.yaml;

      # expose control plane through a vip
      controlplane-vip.source = ./manifests/controlplane-vip.yaml;

      # bgp
      metallb-frr.source = ./manifests/metallb-frr.yaml;
      metallb-config.source = ./manifests/metallb-config.yaml;

      # multus cni for home assistant
      multus-daemonset-thick.source = ./manifests/multus-daemonset-thick.yaml;

      # fix for longhorn paths
      longhorn-fix.source = ./manifests/longhorn-fix.yaml;
    };
  };
}
