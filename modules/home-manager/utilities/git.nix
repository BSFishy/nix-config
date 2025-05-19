{ configurationName, lib, ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = "Matt Provost";
    userEmail =
      if lib.strings.hasPrefix "work" configurationName then
        "mprovost@cloudflare.com"
      else
        "mattprovost6@gmail.com";

    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}
