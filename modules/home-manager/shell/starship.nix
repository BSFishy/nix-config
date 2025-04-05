{ ... }:

{
  programs.starship = {
    enable = true;

    settings = {
      format = builtins.replaceStrings [ "\n" ] [ "" ] ''
        $all
        $container
        $line_break
        $jobs
        $battery
        $time
        $status
        $os
        $shell
        $character
      '';

      add_newline = true;

      c.symbol = " ";

      directory = {
        format = "[$read_only]($read_only_style)[$path]($style) ";
        truncation_length = 8;
        read_only = "󰌾 ";
      };

      direnv = {
        disabled = false;
      };

      docker_context.symbol = " ";

      dotnet.format = "[$symbol($version )]($style)";

      git_branch.symbol = " ";
      golang.symbol = " ";

      hostname = {
        ssh_only = false;
        ssh_symbol = " ";
      };

      java.symbol = " ";

      kubernetes = {
        symbol = "󱃾 ";
        detect_env_vars = [ "KUBIE_ACTIVE" ];
        disabled = false;
      };

      lua.symbol = " ";

      nix_shell = {
        format = "via [$symbol$state]($style) ";
        symbol = "󱄅 ";
      };

      nodejs.symbol = " ";
      package.symbol = "󰏗 ";
      python.symbol = " ";
      rust.symbol = " ";

      sudo.disabled = false;

      username = {
        format = "[$user]($style) on ";
        show_always = true;
      };

      zig.symbol = " ";
    };
  };
}
