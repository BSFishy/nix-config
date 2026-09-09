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
diffs, untracked files, and recent commit history. Confirm that `HEAD` is attached
to a branch before committing. In a detached checkout, preserve the changes and ask
whether to transfer them to an attached worktree or push an explicit ref; do not
create a detached commit implicitly. Stage only the files relevant
to the current change. Never discard, overwrite, or include unrelated changes.
Before committing, review the final staged diff and verify that it contains no
secrets.

When shipping across nested or dependent repositories, map the relationship
before the first commit. For submodules, commit and push the inner repository
before updating the tracked pointer in the containing repository. If a
containing flake consumes the changed repository as an input, update its
relevant lock entry after the upstream revision is available. Before reporting
completion, verify every requested repository is clean, synchronized with its
upstream, and references the shipped revisions through both tracked pointers
and dependency locks.

Keep the current branch and create a conventional commit whose type and optional
scope match the staged diff. Push the current branch, configuring upstream
tracking only when it is absent.

Do not create a branch or pull request. Do not amend commits, force-push, bypass
hooks, or discard existing changes. Ask for clarification only when repository
ownership, change scope, or commit intent is ambiguous.
