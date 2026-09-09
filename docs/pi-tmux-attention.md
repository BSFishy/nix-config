# Pi/tmux attention inbox

**Status:** Work in progress

**Target platform:** macOS and Linux with Pi running inside tmux

**Last reviewed:** 2026-09-09

## Summary

The attention inbox makes concurrent Pi agents discoverable when they finish work or block on user interaction. Pi publishes attention events to the tmux pane in which it runs. tmux displays an aggregate unread count and provides a picker that navigates directly to an agent without implicitly marking it read.

The first implementation stores attention state in tmux pane user options. Pane-local state gives every agent a stable navigation target and disappears with its pane, avoiding a separate daemon or database.

## Goals

- Send a system notification when Pi:
  - settles after processing a prompt; or
  - opens a blocking user-facing prompt, such as an approval request.
- Track attention independently for every tmux pane running Pi.
- Display the number of panes needing attention in the tmux status bar.
- Open a tmux popup listing panes that need attention, including panes in other sessions and windows.
- Navigate to the selected pane without marking it read.
- Mark an item read only when:
  - the user submits another prompt to that Pi instance; or
  - the user invokes an explicit tmux mark-read binding.
- Degrade safely when Pi runs outside tmux or notification delivery fails.
- Keep the implementation managed by Home Manager.

## Non-goals

- Managing or spawning Pi agents.
- Persisting inbox items after their tmux panes are destroyed.
- Synchronizing attention state across machines or tmux servers.
- Inferring arbitrary interactive prompts created by subprocesses that do not use Pi's UI lifecycle.
- Making Notification Center the source of truth.
- Marking an item read merely because its pane becomes visible or focused.
- Replacing the existing project-oriented tmux sessionizer.

## Existing capabilities

The design relies on capabilities already present in the configured tools:

- Pi 0.85.1 exposes `agent_settled`, `ui_prompt_start`, `ui_prompt_end`, `input`, `session_start`, and `session_shutdown` extension events.
- tmux 3.7c supports pane user options, status commands, popups, filtered `choose-tree` views, and direct session/window/pane selection.
- fzf 0.74.3 is installed and is already used by the tmux sessionizer.
- `terminal-notifier` supports macOS notification click commands and application activation.
- `notify-send` supports freedesktop notification actions on compatible Linux desktops.
- The tmux status bar refreshes once per second.
- tmux is configured with `exit-empty off`, so its server remains available between attached clients.

Relevant configuration currently lives in:

- `modules/home-manager/tools/ai/pi.nix`
- `modules/home-manager/editor/tmux.nix`
- `modules/home-manager/editor/tmux-sessionizer.sh`
- `~/.pi/agent/settings.json`
- `~/.pi/agent/extensions/`

## User experience

### Completion

1. The user submits a prompt to Pi.
2. The pane has no outstanding attention state while that prompt is being processed.
3. Pi reaches `agent_settled`.
4. The pane becomes `unread`.
5. macOS displays a completion notification.
6. The tmux status bar shows or increments the attention count.

### Blocking interaction

1. Pi or a Pi extension opens a blocking UI prompt.
2. The pane immediately becomes `waiting`.
3. macOS displays a notification that Pi needs input.
4. The picker places the pane ahead of ordinary unread completions.
5. Closing the blocking prompt changes `waiting` to `unread`; responding to the UI alone does not mark the item read.
6. If Pi continues and settles, it remains `unread` and emits the completion notification.

### Navigation

1. The user invokes the attention-picker tmux binding.
2. A popup lists all `waiting` and `unread` Pi panes across the tmux server.
3. Selecting an entry switches to its session, window, and pane.
4. The selected pane retains its attention state.

### Reading

An item is marked read by either of these actions:

- The user submits a new non-extension-generated prompt in the corresponding Pi instance.
- The user invokes the mark-read tmux binding while focused on the pane.

Focusing, selecting, or viewing a pane has no effect on its state.

## State model

### Attention states

| State | Meaning | Included in count | Picker priority |
|---|---|---:|---:|
| unset | No outstanding attention | No | Not listed |
| `unread` | Pi settled or a user-facing prompt recently closed | Yes | 2 |
| `waiting` | Pi currently has a blocking user-facing prompt open | Yes | 1 |

`waiting` is a more specific form of unread attention. The aggregate count counts panes, not events, so repeated events from one pane do not inflate the count.

### Transitions

| Event | Previous state | New state | Notify |
|---|---|---|---|
| User submits a prompt | any | unset | No |
| `ui_prompt_start` | any | `waiting` | Needs-input notification |
| `ui_prompt_end` | `waiting` | `unread` | No |
| `agent_settled` | any | `unread` | Completion notification |
| Explicit mark-read command | any | unset | No |
| Clean Pi exit | any | unset and metadata removed | No |
| Extension reload | any | unchanged | No |

The extension must not clear attention during a reload or Pi session replacement. A fresh Pi process may clear stale state during startup before registering itself.

## tmux data contract

Each Pi pane owns these tmux user options:

| Option | Required | Value |
|---|---:|---|
| `@pi_attention` | No | `waiting`, `unread`, or unset |
| `@pi_session_id` | Yes while registered | Pi session identifier |
| `@pi_session_file` | No | Pi session file path |
| `@pi_project` | Yes while registered | Displayable project or working-directory name |
| `@pi_label` | No | Pi session name or another concise label |
| `@pi_updated_at` | No | Unix timestamp of the latest state transition |
| `@pi_owner_pid` | Yes while registered | Pi process identifier used for stale-entry checks |

`$TMUX_PANE` is the canonical pane identity. Pane IDs are used for all mutations so renaming a session or window does not orphan state.

The helper treats unknown `@pi_attention` values as unset. Labels must be sanitized to one line before they are included in picker output or notifications.

## Components

### Pi extension

A global TypeScript extension translates Pi lifecycle events into helper invocations.

Responsibilities:

- Register the current pane and Pi session metadata at startup.
- Clear attention for user-originated prompt submission.
- Publish `waiting` on `ui_prompt_start`.
- Publish `unread` on `ui_prompt_end` when the pane is still `waiting`.
- Publish `unread` on `agent_settled`.
- Request macOS notifications without blocking the agent lifecycle.
- Remove pane metadata on clean process exit.
- Preserve attention across extension reload and Pi session replacement.
- No-op tmux integration when `$TMUX` or `$TMUX_PANE` is absent.

Prompt-origin handling must distinguish interactive or RPC user input from extension-generated input. An extension-generated continuation does not demonstrate that the user has read the previous result.

Lifecycle handlers must use `agent_settled` rather than `agent_end`, because settled includes automatic retries, compaction retries, and queued continuations.

### `pi-attention` helper

A shell helper is the only component that directly implements tmux querying and mutation. Centralizing the tmux protocol keeps the Pi extension and tmux bindings consistent.

Proposed interface:

```text
pi-attention register [metadata]
pi-attention set waiting|unread
pi-attention transition waiting|unread waiting|unread [pane-id]
pi-attention read [pane-id]
pi-attention unregister [pane-id]
pi-attention count
pi-attention status
pi-attention list
pi-attention pick
pi-attention focus [pane-id]
pi-attention notify waiting|unread [pane-id]
```

Behavioral contracts:

- Mutation commands target `$TMUX_PANE` by default and accept an explicit pane ID for tmux bindings.
- `count` derives its result from live pane options rather than a cached global counter.
- `status` prints nothing for zero items and a compact icon plus count otherwise.
- `list` emits only valid live entries and sorts `waiting` before `unread`.
- `pick` makes no attention-state mutation.
- `focus` switches the most recently active client to the exact target session, window, and pane without marking it read.
- Notification failures return success to Pi after recording diagnostic output when practical.
- All user-controlled display strings are passed as command arguments rather than evaluated as shell source.

### Status-bar integration

The Gruvbox right status gains a command segment similar to:

```tmux
#(pi-attention status)
```

The status output is intentionally compact. Rendering:

```text
󰚩 3
```

The command derives the count from live panes on each tmux status refresh. This avoids concurrent read-modify-write races between agents updating a shared global count.

### Attention picker

The picker uses `tmux list-panes -a` as its source and fzf in a tmux popup. Each row includes:

- attention state;
- session name;
- window index and name;
- pane index;
- project;
- Pi label when available; and
- pane ID as a non-display or trailing machine field.

Example:

```text
WAITING  fl2:2.1          edgeauth       approval required
UNREAD   home-manager:3.1 home-manager   tmux attention workflow
```

Selection performs these operations in order:

1. Switch the invoking client to the target session.
2. Select the target window by window ID.
3. Select the target pane by pane ID.

The picker refreshes its input each time it opens. If the selected pane disappears before navigation, it exits with a non-destructive tmux message.

### System notifications

On macOS, `terminal-notifier` posts Notification Center notifications with an execution action for `pi-attention focus` and activates Ghostty when clicked. On Linux, `notify-send` requests a freedesktop default action and runs the same focus command when the notification daemon reports a click. Linux action support varies by desktop and notification daemon.

Notification text includes the Pi label and tmux session/window location. Titles are:

- `Pi needs input`
- `Pi finished`

Notification delivery is advisory. tmux pane state remains authoritative when notifications are unsupported, disabled, suppressed by Focus mode or Do Not Disturb, or rejected by system permissions. A notification click never marks the pane read.

## Bindings

The tmux interface uses these bindings:

| Action | Binding | Command |
|---|---|---|
| Open attention picker | `prefix + A` | `display-popup -E 'pi-attention pick'` |
| Mark current pane read | `prefix + U` | `run-shell 'pi-attention read "#{pane_id}"'` |

The existing `prefix + ;` project sessionizer remains unchanged.

## Failure and stale-state handling

- A Pi process outside tmux does not participate in the pane inbox or its target-aware notifications.
- A failed tmux command does not interrupt Pi.
- A failed notification does not alter attention state.
- Clean Pi shutdown unregisters its pane metadata.
- `list` validates `@pi_owner_pid` when feasible and suppresses entries that are no longer owned by a live Pi process.
- A newly started Pi process clears stale state in its pane before registration.
- Destroyed panes require no cleanup because pane-local tmux options are destroyed with them.
- Session and window renames remain safe because mutations and navigation use tmux IDs.

## Security considerations

- Project paths, Pi labels, and session names are untrusted display data.
- Notification display text must be passed as arguments and never evaluated as shell source.
- tmux formats and fzf fields must not be evaluated as shell fragments.
- The picker passes validated tmux IDs to navigation commands.
- Session file paths are metadata only and are not shown by default because they may expose sensitive directory names.

## Configuration layout

The implementation lives in the public Home Manager configuration so the workflow is available on both work and personal machines:

```text
docs/pi-tmux-attention.md
modules/home-manager/tools/ai/pi.nix
modules/home-manager/tools/ai/pi-attention.sh
modules/home-manager/tools/ai/pi-attention-test.sh
modules/home-manager/tools/ai/pi-attention.ts
modules/home-manager/tools/ai/pi-attention-extension-test.sh
```

`pi.nix` builds the helper through a derivation that runs the isolated tmux integration test before exposing the executable. Nix caching means the test runs when the helper or test changes rather than on every activation.

Home Manager is expected to:

- install `pi-attention` into the user profile;
- link the extension into `~/.pi/agent/extensions/`;
- append the tmux bindings and status configuration; and
- make required runtime tools available on `PATH`.

The final filenames may change, but the extension and helper remain separate components with the interfaces described above.

## Implementation plan

### Phase 1: Pane state and Pi lifecycle

- [x] Add the `pi-attention` helper with register, set, read, unregister, count, and list operations.
- [x] Add isolated tmux-server tests for the helper state contract.
- [x] Install the helper in the user profile through Home Manager.
- [x] Activate the temporary Home Manager derivation and verify the installed helper.
- [x] Move the helper, test, and specification into the public Home Manager configuration.
- [x] Verify the public package derivation runs the integration test successfully.
- [ ] Update and activate consuming flakes after publishing the public change.
- [x] Add a global Pi extension.
- [x] Register pane/session metadata on Pi startup.
- [x] Mark the pane unread on `agent_settled`.
- [x] Mark the pane waiting on `ui_prompt_start`.
- [x] Convert waiting to unread on `ui_prompt_end`.
- [x] Clear attention on user-originated prompt submission.
- [x] Preserve state through extension reload and Pi session replacement.
- [x] Clear metadata on clean Pi exit.

### Phase 2: tmux interface

- [x] Add the aggregate status-bar indicator.
- [x] Add the fzf attention picker.
- [x] Navigate to exact sessions, windows, and panes.
- [x] Add the explicit mark-read binding.
- [x] Ensure picker navigation does not mark entries read.

### Phase 3: system notifications

- [x] Add completion notifications.
- [x] Add needs-input notifications.
- [x] Pass notification content safely as arguments.
- [x] Add click-to-focus actions for macOS and compatible Linux desktops.
- [ ] Confirm behavior with macOS notification permissions and Focus mode.
- [x] Ensure notification failures never block or fail Pi event handlers.

### Phase 4: resilience and polish

- [ ] Filter stale process ownership from picker and count results.
- [ ] Handle panes disappearing while the picker is open.
- [ ] Add readable empty-state behavior.
- [ ] Tune status icon, picker fields, keybindings, and notification text.
- [ ] Document troubleshooting and manual commands.

## Verification plan

### Automated checks

- Shell syntax and formatting checks for the helper.
- Type checking or Pi extension loading checks for the TypeScript extension.
- Unit-style tests using an isolated tmux server socket.
- Tests covering count semantics, sorting, read behavior, unregister behavior, and unsafe display strings.
- Home Manager evaluation/build before activation.

### Manual scenarios

1. Run two Pi instances in different sessions and confirm both register independently.
2. Let one instance settle and confirm one unread item, one status count, and one notification.
3. Let the second instance open a confirmation UI and confirm it sorts ahead as waiting.
4. Select each item from the picker and confirm exact pane navigation.
5. Confirm navigation does not alter either item's state.
6. Submit a prompt in one pane and confirm only that pane is marked read.
7. Mark the other pane read with the explicit binding.
8. Queue a follow-up while Pi is running and confirm the pane becomes unread only after final settlement.
9. Reload Pi extensions and confirm attention state survives.
10. Exit Pi cleanly and confirm its entry disappears.
11. Kill a Pi process abruptly and confirm stale filtering prevents a permanent inbox entry.
12. Run Pi outside tmux and confirm the extension remains usable without tmux errors.

## Acceptance criteria

The initial feature is complete when:

- Every tmux pane running Pi has independent attention state.
- Settled and waiting agents produce system notifications.
- The status bar reports the number of panes needing attention.
- A hotkey opens a cross-session picker of exact agent panes.
- Enter navigates to the selected pane without marking it read.
- Submitting another prompt or invoking the explicit binding marks the current item read.
- Clean shutdown and destroyed panes do not leave stale visible entries.
- Pi operation is unaffected when tmux or system notification delivery is unavailable.

## Open questions

1. Should macOS notifications be suppressed when the target pane is already the active pane of an attached client?
2. Should `ui_prompt_end` remain `unread`, as specified, or become read because the user necessarily interacted with the prompt?
3. Should a fresh Pi startup clear existing pane attention immediately, or preserve unread state if the previous process crashed and a new Pi starts in the same pane?
4. Should the picker show all registered Pi panes behind an fzf toggle, or only panes needing attention?
5. Should normal slash commands that do not start an agent turn count as user acknowledgement?
