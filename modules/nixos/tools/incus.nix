{ pkgs, username, ... }:

let
  incus-connect = pkgs.writeShellScriptBin "incus-connect" (builtins.readFile ./incus-connect.sh);
in
{
  virtualisation.incus.enable = true;

  networking.nftables.enable = true;
  networking.firewall.trustedInterfaces = [
    # Required for networking inside the containers
    "incusbr0"
  ];

  environment.defaultPackages = [
    incus-connect
  ];

  users.users.${username}.extraGroups = [
    # give admin permissions to use incus commands
    "incus-admin"
  ];
}
