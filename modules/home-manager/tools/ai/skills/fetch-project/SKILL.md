---
name: fetch-project
description: >
  Find or clone public documentation or source repositories into ~/projects so
  the agent can read local files directly instead of guessing or relying on web
  fetches. Use when docs or source code for a tool, service, library, or public
  project are needed and a local checkout may already exist.
---

# Fetch Project

## When to use

Load this skill when you need authoritative docs or source code for a public
project and want to inspect it locally with normal file tools (`read`, `rg`,
`find`, `bash`) instead of assuming behavior or depending on `curl`/`webfetch`.

Typical cases:

- API, CLI, SDK, or framework documentation
- Service, library, or tool source code
- Config schemas, examples, changelogs, or migration guides
- Any task where reading the actual repo is safer than guessing

## Goal

Prefer an existing checkout under `~/projects`. If none exists, ask the user for
what to pull, verify it still is not present, clone it into `~/projects`, check
out the relevant release branch or tag when needed, then use the local repo for
inspection.

## Workflow

1. **Check `~/projects` first**
   - Search `~/projects` for likely matching directories before asking the user.
   - Use broad but efficient searches: `find`, `rg`, or `fd` if available.
   - Try likely names, org/repo patterns, and close variants.
   - If multiple plausible matches exist, present them briefly and ask which one
     to use.

2. **Use an existing local repo when found**
   - Confirm the chosen path.
   - Determine whether the task depends on a specific release, version, branch,
     or tag.
   - If the correct version is not clear, ask the user which release branch or
     tag should be used.
   - Check out the requested branch or tag before reading files.
   - Read docs and source from that checkout directly.
   - Prefer README files, docs directories, examples, and explicit config over
     inference.

3. **Ask before cloning when nothing is found**
   - Tell the user you could not find a matching repo under `~/projects`.
   - Ask what repo or URL to pull.
   - If the destination directory name is ambiguous, ask where under
     `~/projects` it should live.

4. **Re-check before cloning**
   - After the user specifies the repo, perform one more check that the target
     repo does not already exist in `~/projects`.
   - If it now exists, use the existing checkout instead of cloning.

5. **Clone only after the second check passes**
   - Clone into `~/projects/<repo-name>` unless the user specifies a different
     destination.
   - Prefer a normal git clone of the public repo.
   - Do not overwrite, delete, or reclone an existing directory.

6. **Check out the correct version**
   - Before inspecting files, determine whether the task requires a specific
     release branch, version, or tag.
   - If the correct version is not clear, ask the user.
   - Check out the requested branch or tag before reading docs or code.
   - If no version is specified and the task appears version-sensitive, ask
     instead of assuming the default branch is correct.

7. **Inspect locally after clone or checkout**
   - Use the checked out repo state as the source of truth.
   - Search and read files locally rather than falling back to web fetches.
   - Cite the local repo path and checked out ref when practical.

## Operating rules

- Always check `~/projects` before asking the user.
- Always ask before cloning anything.
- Always perform the second existence check after the user provides the repo.
- Always determine the correct release branch or tag before trusting the docs or
  code for version-sensitive questions.
- Never assume the repo name or hosting location when it is unclear.
- Never overwrite an existing directory in `~/projects`.
- Prefer local file inspection over remote fetching once a checkout exists.
- If the user wants only docs and a docs repo is separate from the main source
  repo, ask which repo they want.
- If authentication or network access is required, surface that clearly and ask
  the user how to proceed.

## Suggested commands

Search for likely repos:

```bash
find ~/projects -maxdepth 3 -type d \( -iname '*name*' -o -iname '*org*' \)
```

Check for a specific destination before clone:

```bash
test -e ~/projects/<repo-name> && echo exists || echo missing
```

Clone after confirmation:

```bash
git clone <repo-url> ~/projects/<repo-name>
```

List likely release refs:

```bash
git -C ~/projects/<repo-name> branch -a
git -C ~/projects/<repo-name> tag -l
```

Check out the requested ref:

```bash
git -C ~/projects/<repo-name> checkout <branch-or-tag>
```

Inspect the local checkout:

```bash
rg -n "<query>" ~/projects/<repo-name>
find ~/projects/<repo-name> -maxdepth 2 -type f
```

## Response pattern

When a repo is already present:

1. Say you found it under `~/projects`.
2. Name the path.
3. Confirm or ask which release branch or tag should be used when relevant.
4. Check out that ref.
5. Continue by reading local files.

When no repo is present:

1. Say you could not find it under `~/projects`.
2. Ask what repo or URL to pull.
3. Ask which release branch or tag should be used when relevant.
4. After the user answers, re-check.
5. Clone only if still absent.
6. Check out the requested ref.
7. Continue with local inspection.
