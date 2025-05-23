{ ... }:

{
  # Let k3s work
  virtualisation.containerd.enable = true;
  virtualisation.docker.enable = false;

  services.k3s = {
    enable = true;
  };
}
