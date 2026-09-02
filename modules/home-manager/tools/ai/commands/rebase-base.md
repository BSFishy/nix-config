---
description: Rebase the current branch onto its base, resolve conflicts, verify, and push safely
---

You are running the `/rebase-base` command. Rebase the current branch onto its
latest base branch, resolve conflicts, verify the result, and push the rebased
branch end-to-end.

Use `$1` as the base branch when provided. Otherwise, determine the base from
the current pull or merge request, falling back to the repository's default
branch.

Before changing Git state:

- Inspect the current branch, upstream, status, staged and unstaged diffs,
  untracked files, remotes, and recent commits.
- Confirm the working tree contains no unrelated work that the rebase could
  overwrite. Never stash, discard, or include unrelated changes without the
  user's approval.
- Fetch the latest base branch from the appropriate remote.

Rebase the current branch onto the remote-tracking base. Resolve conflicts by
preserving the intent of both changes whenever they are compatible. If the
correct behavior is ambiguous, stop and ask one focused question rather than
guessing.

Treat source files as authoritative over generated artifacts. When conflicts
are confined to generated files, first confirm the source merge is correct,
then run the repository's canonical generation command to overwrite the
conflicted outputs. Stage the regenerated files and continue the rebase. An
intermediate diagnostic caused by conflict markers is acceptable only when the
generator subsequently replaces them, exits successfully, and the final files
are conflict-free. Do not hand-merge opaque generated payloads when they can be
reproduced from source.

After resolving conflicts:

- Continue the rebase non-interactively while preserving the original commit
  messages.
- Run the repository's documented generation, formatting, lint, and test
  checks relevant to the changed files.
- Verify there are no conflict markers, whitespace errors, unexpected files,
  or unrelated changes in the final diff against the base.
- Confirm the base branch is an ancestor of the rebased HEAD.

Push the current branch to its existing remote branch using
`--force-with-lease`, never an unrestricted force push. Confirm the working
tree and upstream are synchronized, then return the new HEAD commit, resolved
conflicts, verification performed, and pull or merge request URL.

Additional context and arguments:

$ARGUMENTS
