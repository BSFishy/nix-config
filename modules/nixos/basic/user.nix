{ username, ... }:

{
  users.users.${username} = {
    isNormalUser = true;
    description = "Matt Provost";

    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
}
