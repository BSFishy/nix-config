{ ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      add_newline = true;

      character = {
        success_symbol = "[\u276F](bold green)";
        error_symbol = "[\u2717](bold red)";
      };

      directory = {
        format = "[$read_only]($read_only_style)[$path]($style) ";
        truncation_length = 8;
      };

      dotnet = {
        format = "[$symbol($version )]($style)";
      };

      hostname = {
        ssh_only = false;
      };

      sudo = {
        disabled = false;
      };

      username = {
        format = "[$user]($style) on ";
        show_always = true;
      };
    };
  };
}
