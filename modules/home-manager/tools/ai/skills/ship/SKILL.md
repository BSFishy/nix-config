---
name: ship
description: >
  Stage, conventionally commit, and push changes in a personal repository. Use
  when asked to ship, publish, or commit and push personal project changes.
---

# Ship Personal Changes

Confirm from the configured Git remotes that the repository belongs to the user
and is personal. If ownership is ambiguous or appears organizational, ask before
changing Git state.

Inspect the current branch, upstream, status, complete staged and unstaged
diffs, untracked files, and recent commit history. Stage only the files relevant
to the current change. Never discard, overwrite, or include unrelated changes.
Before committing, review the final staged diff and verify that it contains no
secrets.

Keep the current branch and create a conventional commit whose type and optional
scope match the staged diff. Push the current branch, configuring upstream
tracking only when it is absent.

Do not create a branch or pull request. Do not amend commits, force-push, bypass
hooks, or discard existing changes. Ask for clarification only when repository
ownership, change scope, or commit intent is ambiguous.
