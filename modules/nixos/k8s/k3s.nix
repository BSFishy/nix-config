{ ... }:

{
  # Let k3s work
  virtualisation.containerd.enable = true;
  virtualisation.docker.enable = false;

  services.k3s = {
    enable = true;
  };

  # run the service as root so it has access to /dev/kmsg
  systemd.services.k3s.serviceConfig = {
    User = "root";
    Group = "root";
  };
}
