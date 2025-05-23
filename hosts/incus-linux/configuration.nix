# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  modulesPath,
  lib,
  pkgs,
  ...
}:

let
  incusConfig = "/etc/nixos/incus.nix";
in
{
  imports = [
    # Include the default incus configuration.
    "${modulesPath}/virtualisation/lxc-container.nix"
  ] ++ lib.optional (builtins.pathExists incusConfig) incusConfig;

  boot.isContainer = true;

  networking = {
    dhcpcd.enable = false;
    useDHCP = false;
    useHostResolvConf = false;
  };

  systemd.network = {
    enable = true;
    networks."50-eth0" = {
      matchConfig.Name = "eth0";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

  # Set the default shell to zsh
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  users.users.matt = {
    isNormalUser = true;
    description = "Matt Provost";

    extraGroups = [
      "networkmanager"
      "wheel"
      "k8s"
    ];
  };

  users.groups.k8s = { };

  system.stateVersion = "25.11"; # Did you read the comment?
}
