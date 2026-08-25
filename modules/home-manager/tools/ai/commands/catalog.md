---
description: Inventory working-tree changes by purpose, risk, and test coverage
---

You are running the `/catalog` command. Inspect the current Git working tree
without modifying it.

Review staged, unstaged, and untracked files, reading file contents where needed
to understand each change. Group related changes by purpose rather than merely
listing them by Git status.

For each group, report:

- Its purpose
- Its files, identifying each as staged, unstaged, or untracked
- Its behavioral, configuration, or documentation impact
- Risks, uncertainties, compatibility concerns, or incomplete work
- Existing tests and tests that appear to be missing

Also report the current branch, upstream relationship, and whether the branch is
ahead or behind. Distinguish generated files and noise-only changes from
intentional changes. Clearly separate verified findings from inference.

Do not edit, stage, format, build, test, commit, or otherwise modify the
repository.

Use the following additional context or scope when provided:

$ARGUMENTS
