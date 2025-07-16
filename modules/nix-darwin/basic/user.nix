{ username, ... }:

{
  # configure user profile
  users.users.${username} = {
    home = "/Users/${username}";
  };
}
