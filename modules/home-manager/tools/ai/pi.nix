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
  piAttention = pkgs.runCommand "pi-attention" { nativeBuildInputs = [ pkgs.tmux ]; } ''
    export HOME="$TMPDIR"
    PI_ATTENTION=${piAttentionUnchecked}/bin/pi-attention \
      TMUX_BIN=${pkgs.tmux}/bin/tmux \
      ${pkgs.bash}/bin/bash ${./pi-attention-test.sh}

    mkdir -p "$out/bin"
    ln -s ${piAttentionUnchecked}/bin/pi-attention "$out/bin/pi-attention"
  '';
in
{
  options.programs.pi.settings = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = { };
    description = "Settings written to Pi's global settings file.";
  };

  config = {
    programs.pi.settings.tuiMode = "fullscreen";

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
