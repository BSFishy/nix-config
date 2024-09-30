{ ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      add_newline = true;

      aws.symbol = "  ";

      buf.symbol = " ";

      c.symbol = " ";

      conda.symbol = " ";

      crystal.symbol = " ";

      dart.symbol = " ";

      directory = {
        format = "[$read_only]($read_only_style)[$path]($style) ";
        truncation_length = 8;
        read_only = " 󰌾";
      };

      direnv = {
        disabled = false;
        # until https://github.com/starship/starship/pull/5969 is merged
        style = "bold bright-yellow";
      };

      docker_context.symbol = " ";

      dotnet.format = "[$symbol($version )]($style)";

      elixir.symbol = " ";

      elm.symbol = " ";

      fennel.symbol = " ";

      fossil_branch.symbol = " ";

      git_branch.symbol = " ";

      golang.symbol = " ";

      guix_shell.symbol = " ";

      haskell.symbol = " ";

      haxe.symbol = " ";

      hg_branch.symbol = " ";

      hostname = {
        ssh_only = false;
        ssh_symbol = " ";
      };

      java.symbol = " ";

      julia.symbol = " ";

      kotlin.symbol = " ";

      kubernetes = {
        symbol = "󱃾 ";
        detect_env_vars = [ "KUBIE_ACTIVE" ];
        disabled = false;
      };

      lua.symbol = " ";

      memory_usage.symbol = "󰍛 ";

      meson.symbol = "󰔷 ";

      nim.symbol = "󰆥 ";

      nix_shell = {
        format = "via [$symbol$state]($style) ";
        symbol = " ";
      };

      nodejs.symbol = " ";

      ocaml.symbol = " ";

      os.symbols = {
        Alpaquita = " ";
        Alpine = " ";
        AlmaLinux = " ";
        Amazon = " ";
        Android = " ";
        Arch = " ";
        Artix = " ";
        CentOS = " ";
        Debian = " ";
        DragonFly = " ";
        Emscripten = " ";
        EndeavourOS = " ";
        Fedora = " ";
        FreeBSD = " ";
        Garuda = "󰛓 ";
        Gentoo = " ";
        HardenedBSD = "󰞌 ";
        Illumos = "󰈸 ";
        Kali = " ";
        Linux = " ";
        Mabox = " ";
        Macos = " ";
        Manjaro = " ";
        Mariner = " ";
        MidnightBSD = " ";
        Mint = " ";
        NetBSD = " ";
        NixOS = " ";
        OpenBSD = "󰈺 ";
        openSUSE = " ";
        OracleLinux = "󰌷 ";
        Pop = " ";
        Raspbian = " ";
        Redhat = " ";
        RedHatEnterprise = " ";
        RockyLinux = " ";
        Redox = "󰀘 ";
        Solus = "󰠳 ";
        SUSE = " ";
        Ubuntu = " ";
        Unknown = " ";
        Void = " ";
        Windows = "󰍲 ";
      };

      package.symbol = "󰏗 ";

      perl.symbol = " ";

      php.symbol = " ";

      pijul_channel.symbol = " ";

      python.symbol = " ";

      rlang.symbol = "󰟔 ";

      ruby.symbol = " ";

      rust.symbol = " ";

      scala.symbol = " ";

      sudo.disabled = false;

      swift.symbol = " ";

      username = {
        format = "[$user]($style) on ";
        show_always = true;
      };

      zig.symbol = " ";
    };
  };
}
