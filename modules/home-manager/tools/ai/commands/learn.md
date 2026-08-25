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

Before making any changes to nix-managed files, you need to know where the
repository lives on this machine. To find it:

1. Check your long-term memory / notes for a previously saved path.
2. If not found, **ask the user** where their nix config repo is.
3. Once you have the path, save it to your long-term memory for future sessions.

The repository has this structure (relative to its root):

| Artifact | Relative path in repo |
|---|---|
| Global rules (AGENTS.md) | `remote/modules/home-manager/tools/AGENTS.md` |
| Work-specific rules | `work-rules.md` (in repo root) |
| Commands | `remote/modules/home-manager/tools/ai/commands/<name>.md` |
| Skills (global) | `remote/modules/home-manager/tools/ai/skills/<name>/SKILL.md` |
| Plugins | `remote/modules/home-manager/tools/opencode-plugins/<name>.js` |
| Nix wiring | `remote/modules/home-manager/tools/ai/opencode.nix` |

Project-scoped docs are NOT nix-managed — they live in the project repo itself
at `docs/<name>.md` and can be edited directly.

After editing any nix-managed source file, remind the user they need to rebuild
home-manager to deploy the changes.

## What to propose

Review everything that happened in this session — instructions the user gave,
corrections they made, preferences they expressed, patterns that emerged,
decisions that were reached, and workflows that worked well (or didn't).

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

### 4. Skills (global, cross-project)

Knowledge or workflows that transcend any single project. Skills are
nix-managed and available globally across all machines. Examples: how to
stage/commit/push changes, how to write good PR descriptions, how to debug
a k8s pod, how to run a database migration.

A skill is appropriate when the knowledge applies regardless of which project
the user is working in.

**Note:** new skills require wiring in the nix config to be deployed. If you
propose a new skill, include the nix wiring change that would be needed.

## Proposal format

For each candidate insight, present it as:

```
Category: rule | command | doc | skill
Proposed: <concise description of what to create or change>
Source: <brief description of the session moment that inspired it>
```

Group related proposals together by category.

## Self-improvement

After handling proposals, review this `/learn` command itself. Consider:

- Did the session surface a pattern that `/learn` should look for but doesn't?
- Is there a step in this workflow that felt clunky or incomplete?
- Could the output format be improved?

Present self-improvement suggestions in the same propose-then-confirm style.
The source file for this command lives in the system config repository at:
`remote/modules/home-manager/tools/ai/commands/learn.md`

## Process

1. Summarize the session briefly (3-5 bullet points of key moments).
2. Present all proposals grouped by category.
3. Ask the user which proposals to accept (they may edit, merge, or reject).
4. For nix-managed files: locate the system config repo (ask if unknown, save
   to memory for next time). Edit the source files there. Show diffs.
5. For project docs: edit directly in the project's `docs/` directory.
6. Present any self-improvement proposals for this command.
7. If the user accepts, apply those too.
8. If any nix-managed files were changed, remind the user to rebuild.

$ARGUMENTS
