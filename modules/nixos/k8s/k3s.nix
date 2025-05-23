{ ... }:

{
  # Let k3s work
  virtualisation.containerd.enable = true;
  virtualisation.docker.enable = false;

  services.k3s = {
    enable = true;
    extraFlags = "--write-kubeconfig-group=k8s --write-kubeconfig-mode=0640";
  };

  # run the service as root so it has access to /dev/kmsg
  systemd.services.k3s.serviceConfig = {
    User = "root";
    Group = "root";
  };

  # this is also needed for /dev/kmsg
  systemd.services.k3s.serviceConfig.Capabilities =
    "CAP_SYSLOG CAP_NET_ADMIN CAP_NET_RAW CAP_SYS_ADMIN";
  systemd.services.k3s.serviceConfig.CapabilityBoundingSet =
    "CAP_SYSLOG CAP_NET_ADMIN CAP_NET_RAW CAP_SYS_ADMIN";
}
