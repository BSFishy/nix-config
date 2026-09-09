{
  config,
  lib,
  llmPkgs,
  pkgs,
  ...
}:

let
  piAttentionUnchecked = pkgs.writeShellScriptBin "pi-attention" (
    builtins.readFile ./pi-attention.sh
  );
  alerter = pkgs.runCommand "alerter-26.5" { nativeBuildInputs = [ pkgs.unzip ]; } ''
    mkdir -p "$out/bin"
    unzip -j ${
      pkgs.fetchurl {
        url = "https://github.com/vjeantet/alerter/releases/download/v26.5/alerter-26.5.zip";
        hash = "sha256-EfY83cm7P4VU7Zt2JjKhIM+nvuBePAnWVzSCPgnSTxA=";
      }
    } alerter -d "$out/bin"
    chmod +x "$out/bin/alerter"
  '';
  notificationPackage = if pkgs.stdenv.hostPlatform.isDarwin then alerter else pkgs.libnotify;
  piAttentionRuntimePath = lib.makeBinPath (
    [
      pkgs.coreutils
      pkgs.fzf
      pkgs.gawk
      pkgs.tmux
      notificationPackage
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.glib ]
  );
  piAttention =
    pkgs.runCommand "pi-attention"
      {
        nativeBuildInputs = [
          pkgs.makeWrapper
          pkgs.tmux
        ];
      }
      ''
        export HOME="$TMPDIR"
        PI_ATTENTION=${piAttentionUnchecked}/bin/pi-attention \
          TMUX_BIN=${pkgs.tmux}/bin/tmux \
          ${pkgs.bash}/bin/bash ${./pi-attention-test.sh}

        mkdir -p "$TMPDIR/pi-home"
        HOME="$TMPDIR/pi-home" ${llmPkgs.pi}/bin/pi \
          --extension ${./pi-attention.ts} \
          --list-models > /dev/null

        PATH=${piAttentionUnchecked}/bin:$PATH \
          PI_BIN=${llmPkgs.pi}/bin/pi \
          PI_EXTENSION=${./pi-attention.ts} \
          TMUX_BIN=${pkgs.tmux}/bin/tmux \
          ${pkgs.bash}/bin/bash ${./pi-attention-extension-test.sh}

        mkdir -p "$out/bin"
        makeWrapper ${piAttentionUnchecked}/bin/pi-attention "$out/bin/pi-attention" \
          --prefix PATH : ${piAttentionRuntimePath}
      '';
in
{
  options.programs.pi.settings = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = { };
    description = "Settings written to Pi's global settings file.";
  };

  config = {
    programs.pi.settings = {
      defaultProvider = lib.mkDefault "openai-codex";
      defaultModel = lib.mkDefault "gpt-5.6-terra";
      defaultThinkingLevel = lib.mkDefault "medium";
      tuiMode = "fullscreen";
    };

    programs.pi.settings.defaultTools = [
      "read"
      "bash"
      "edit"
      "write"
      "grep"
      "find"
      "ls"
    ];

    home.file.".pi/agent/settings.json".text = builtins.toJSON config.programs.pi.settings;

    home.packages = [
      llmPkgs.pi
      piAttention
    ];

    home.file.".pi/agent/AGENTS.md".source = ../AGENTS.md;
    home.file.".pi/agent/extensions/pi-attention.ts".source = ./pi-attention.ts;

    home.file.".pi/agent/skills/documentation".source = ./skills/documentation;
    home.file.".pi/agent/skills/command-not-found".source = ./skills/command-not-found;
    home.file.".pi/agent/skills/ship".source = ./skills/ship;
    home.file.".pi/agent/skills/fetch-project".source = ./skills/fetch-project;
    home.file.".pi/agent/skills/open-code-review-delegate".source = ./skills/open-code-review-delegate;
    home.file.".pi/agent/skills/stateful-k8s-recovery".source = ./skills/stateful-k8s-recovery;

    home.file.".pi/agent/prompts/catalog.md".source = ./commands/catalog.md;
    home.file.".pi/agent/prompts/learn.md".source = ./commands/learn.md;
    home.file.".pi/agent/prompts/rebase-base.md".source = ./commands/rebase-base.md;
  };
}
