---
description: Reflect on the current session to codify decisions as rules, commands, docs, or skills
---

You are running the `/learn` command. Your job is to reflect on the conversation
that has taken place in this session and help the user distill it into durable
knowledge.

## System config repository

This user manages their agent configuration (rules, commands, skills, plugins)
declaratively in a nix home-manager repository. All deployed config files are
read-only symlinks — you must edit the **source files** in the repository, not
the deployed copies.

Before proposing or changing any nix-managed artifacts, you need to know where
the repository lives on this machine. If the path is not clear from the session,
ask the user where their nix config repo is.

After locating it, inspect the relevant source files before drafting proposals.
Use the deployed configuration only as a fallback for discovery; the source
repository determines whether a proposal is new, redundant, or already covered.
If the invoked `/learn` prompt differs from the nix-managed source you read,
treat the deployed prompt as stale and remind the user to rebuild home-manager
before relying on deployed command behavior.

The personal config repo stores these files directly under `modules/`. The work
config repo stores the same tree in a `remote/` submodule. Check which layout is
present before constructing paths. If the expected layout is absent, search the
repo for analogous `AGENTS.md`, `commands`, `skills`, plugin, and nix wiring
paths before asking again or failing.

Typical repository structures, relative to the repo root:

| Artifact | Personal path | Work path |
|---|---|---|
| Global rules (AGENTS.md) | `modules/home-manager/tools/AGENTS.md` | `remote/modules/home-manager/tools/AGENTS.md` |
| Work-specific rules | - | `work-rules.md` |
| Commands | `modules/home-manager/tools/ai/commands/<name>.md` | `remote/modules/home-manager/tools/ai/commands/<name>.md` |
| Skills (global) | `modules/home-manager/tools/ai/skills/<name>/SKILL.md` | `remote/modules/home-manager/tools/ai/skills/<name>/SKILL.md` |
| Plugins | `modules/home-manager/tools/opencode-plugins/<name>.js` | `remote/modules/home-manager/tools/opencode-plugins/<name>.js` |
| Nix wiring | `modules/home-manager/tools/ai/opencode.nix` | `remote/modules/home-manager/tools/ai/opencode.nix` |

Project-scoped docs are NOT nix-managed — they live in the project repo itself
at `docs/<name>.md` and can be edited directly. Inspect relevant existing
project docs before proposing a project-doc change. When a repository-root
`todo.md` exists, inspect it as a status tracker rather than a durable doc;
ask whether accepted tracker updates should remain untracked or be committed.

After editing any nix-managed source file, remind the user they need to rebuild
home-manager to deploy the changes.

## What to propose

Review everything that happened in this session — instructions the user gave,
corrections they made, preferences they expressed, patterns that emerged,
decisions that were reached, and workflows that worked well (or didn't).

Do not propose candidate insights that were already implemented during this
session; mention them only in the session summary.

Classify each candidate insight into one of four categories:

### 1. Rules

Behavioral instructions that shape how the agent acts across all sessions.
These go into `AGENTS.md` (global) or `work-rules.md` (work-specific overlay).

Good rules are:
- **Durable** — apply across sessions and projects, not one-off instructions.
- **Actionable** — phrased as imperatives the agent can follow.
- **Non-obvious** — don't codify things the model already does well by default.
- Non-redundant with existing rules.

### 2. Commands

Reusable prompt templates invoked as slash commands. A command is appropriate
when a workflow is repeated across sessions and benefits from a consistent
prompt structure. Commands are global (available in every project).

Commands are markdown files with optional frontmatter (`description`, `agent`,
`model`). The body is the prompt template. `$ARGUMENTS` is replaced with
anything the user types after the command name.

### 3. Docs (project-scoped)

Knowledge that is specific to the current project. Docs live in the project's
`docs/` directory and are loaded on demand by the agent. These are committed
to the project repo and shared with the team.

A doc is appropriate when the knowledge is about this specific project's
architecture, conventions, gotchas, or domain concepts.

Docs are just markdown files with an optional `description` in the frontmatter:
```
---
description: Short description of when this doc is relevant
---

Content here.
```

### 4. Skills

A project-specific workflow belongs in `.agents/skills/<name>/SKILL.md` in
that project. A global, cross-project workflow belongs in the nix-managed skills
tree and is available on every machine. Examples include staging/committing,
writing PR descriptions, debugging a Kubernetes pod, and database migrations.

A global skill is appropriate only when the knowledge applies regardless of
which project the user is working in. New global skills require wiring in both
`modules/home-manager/tools/ai/pi.nix` and
`modules/home-manager/tools/ai/opencode.nix`; include both changes in the
proposal. Project skills use Pi's project discovery and do not require global
Nix wiring.

## Proposal format

For each candidate insight, present it as:

```
Category: rule | command | doc | skill
Proposed: <concise description of what to create or change>
Source: <brief description of the session moment that inspired it>
```

Group related proposals together by category.

## Self-improvement

Before asking the user to approve any proposals, review this `/learn` command
itself. Consider:

- Did the session surface a pattern that `/learn` should look for but doesn't?
- Is there a step in this workflow that felt clunky or incomplete?
- Could the output format be improved?

Include self-improvement suggestions with the regular proposals and present them
in the same format. The source file for this command lives in the system config
repository at the command path for the detected personal or work layout.

## Process

1. Locate the system config repo and inspect relevant existing source artifacts
   for overlap. Inspect a repository-root `todo.md` when present.
2. Summarize the session briefly (3-5 bullet points of key moments).
3. When the session includes an outage, failed deployment, or stateful recovery,
   identify the verified failure chain and consider a project runbook proposal
   covering safe diagnosis, recovery, and prevention.
4. Present all regular and self-improvement proposals grouped by category.
5. Ask the user which proposals to accept in one confirmation covering every
   proposed edit. Do not edit anything before receiving that confirmation.
6. For nix-managed files, edit the accepted source files and show diffs.
7. For project docs, edit accepted changes directly in the project's `docs/`
   directory. For accepted tracker updates, follow the user's retention choice.
8. If any nix-managed files were changed, remind the user to rebuild.

$ARGUMENTS
