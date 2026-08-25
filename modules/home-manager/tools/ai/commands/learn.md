---
description: Reflect on the current session to codify decisions as agent rules and improve this command
---

You are running the `/learn` command. Your job is to reflect on the conversation
that has taken place in this session and help the user distill it into durable
knowledge. You have two responsibilities:

## 1. Propose new agent rules

Review everything that happened in this session — instructions the user gave,
corrections they made, preferences they expressed, patterns that emerged,
decisions that were reached, and workflows that worked well (or didn't).

For each candidate insight, present it to the user as a **proposed rule** using
this format:

```
Proposed rule: <concise, imperative statement>
Source: <brief description of the moment/decision that inspired it>
```

Group related proposals together. After presenting all proposals, ask the user
which ones (if any) they'd like to codify. The user may also edit, merge, or
reject proposals.

For every rule the user accepts:

1. Read the current `~/.config/opencode/AGENTS.md` file.
2. Determine where the new rule fits best — does it belong in an existing
   section, or does it warrant a new section?
3. Append or integrate the rule cleanly, preserving the existing voice and
   structure of the file.
4. Show the user the diff of what changed.

Guidelines for good rules:
- Rules should be **durable** — they should apply across sessions and projects,
  not be one-off instructions.
- Rules should be **actionable** — phrased as imperatives the agent can follow.
- Rules should be **non-obvious** — don't codify things the model already does
  well by default.
- Avoid redundancy with rules that already exist in AGENTS.md.
- When in doubt, ask the user whether something is a lasting preference or a
  one-time request.

## 2. Self-improvement

After handling rule proposals, review your own prompt (this `/learn` command
definition at `~/.config/opencode/commands/learn.md`). Consider:

- Did the session surface a pattern that `/learn` should look for but currently
  doesn't?
- Is there a step in this workflow that felt clunky or incomplete?
- Could the output format be improved?

If you have suggestions for improving this command, present them to the user in
the same propose-then-confirm style. Only modify the command file if the user
approves.

## Process

1. Summarize the session briefly (3-5 bullet points of key moments).
2. Present proposed rules.
3. Confirm with user, then apply accepted rules to AGENTS.md.
4. Present any self-improvement proposals for this command.
5. Confirm with user, then apply accepted improvements to this file.

$ARGUMENTS
