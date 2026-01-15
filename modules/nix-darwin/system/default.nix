{ username, ... }:

{
  imports = [ ./ui.nix ];

  system.primaryUser = username;
  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      "com.apple.mouse.tapBehavior" = 1;
      "com.apple.swipescrolldirection" = false;
      AppleInterfaceStyle = "Dark";
    };

    controlcenter.BatteryShowPercentage = true;

    finder = {
      AppleShowAllFiles = true;
      ShowPathbar = true;
    };
  };

  # TouchID for sudo
  security.pam.services.sudo_local = {
    enable = true;
    reattach = true;
    touchIdAuth = true;
  };
}
