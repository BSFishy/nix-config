---
name: command-not-found
description: >
  Recover from command-not-found and missing executable errors by running the
  command temporarily from nixpkgs with nix-shell.
---

# Command Not Found Recovery

## When To Use

Load this skill when a command required for the current task is unavailable.
The system has Nix installed even when the requested command is absent.

## Process

1. Choose the likely nixpkgs package attribute using best judgment. Command and
   package names often match, but use known mappings when they do not (for
   example, `cargo` -> `rustup`, and `npm` or npm tooling -> `nodejs_22` or a
   project-appropriate Node package). If uncertain, search first:

   ```bash
   nix search nixpkgs <search-term>
   ```

2. Run the original command in a temporary environment:

   ```bash
   nix-shell -p <package-attribute> --run '<command and arguments>'
   ```

3. If the package does not provide the command, search related terms and retry
   with the correct package attribute.

4. Report the package used when it differs from the command name.

Do not permanently install the package or modify project or system Nix
configuration unless the user explicitly requests it.
