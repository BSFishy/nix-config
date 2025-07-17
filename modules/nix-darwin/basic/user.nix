{ lib, username, ... }:

{
  # configure user profile
  users.users.${username} = {
    home = lib.mkDefault "/Users/${username}";
  };
}
