---
name: documentation
description: >
  Guidelines for writing code comments, docstrings, commit messages, and PR
  descriptions. Enforces the principle of decoupled artifacts: commit messages
  and PR descriptions describe the delta (change over time), while code comments
  describe the state (the system as it exists right now). Load this skill when
  writing documentation, comments, docstrings, commit messages, or PR
  descriptions.
---

# Code Documentation & Comments

## When to use

Load this skill whenever you are:

- Writing or reviewing code comments or docstrings
- Drafting commit messages or PR descriptions
- Writing architectural documentation or ADRs
- Reviewing documentation for quality

## Core Philosophy: Decoupled Artifacts

There are two distinct types of written artifacts in software and they must
never be mixed:

| Artifact | Describes | Tense | Lives in |
|----------|-----------|-------|----------|
| Code comments / docstrings | **The state** (the system as it exists right now) | Present | Source files |
| Commit messages / PR descriptions | **The delta** (the change over time) | Past/imperative | Git history |

A code comment that says "Fixed the race condition" has failed. It married a
temporal event (the fix) to a spatial location (the code). The comment will
outlive the context of the fix and become meaningless noise.

---

## Rules

### 1. Comments Describe State, Never Process

Write all code comments as if the codebase materialized fully formed. No
history, no iterations, no journey. The code simply *is*.

#### Good

```python
# Acquire the lock before reading the counter to prevent
# concurrent readers from observing a partially-updated value.
with self._lock:
    return self._counter
```

```go
// retryLimit caps retries at 3 to bound total latency under the
// upstream gateway's 30-second timeout.
const retryLimit = 3
```

```rust
/// Connections are pooled per-host to amortize TLS handshake cost.
/// The pool evicts idle connections after 90 seconds to avoid holding
/// stale file descriptors against load-balanced backends.
fn get_connection(&self, host: &str) -> Connection {
```

#### Bad

```python
# Fixed the race condition that was causing flaky test_counter_increment
# failures in CI. Previously we read without locking.
with self._lock:
    return self._counter
```

```go
// Changed from 5 to 3 after we discovered the gateway times out at 30s.
// See PR #482 for the investigation.
const retryLimit = 3
```

```rust
/// We used to create a new connection for every request but that was
/// too slow. Switched to connection pooling in the v2.3 refactor.
fn get_connection(&self, host: &str) -> Connection {
```

### 2. Affirmative Rationale ("We Do", Never "We Don't")

Explain why the current approach is correct and what guarantees it provides.
Do not explain why rejected or legacy approaches were avoided. If an
alternative is no longer in the codebase, it does not exist. Do not document
ghosts.

#### Good

```typescript
// SHA-256 provides collision resistance sufficient for content-addressed
// storage where uniqueness, not secrecy, is the requirement.
const hash = crypto.createHash("sha256");
```

#### Bad

```typescript
// We don't use MD5 here because it's vulnerable to collision attacks.
// We also considered SHA-1 but it was deprecated.
const hash = crypto.createHash("sha256");
```

### 3. Evergreen Comments (High Durability)

Document intent, contracts, invariants, and non-obvious business logic.
Do not narrate implementation mechanics that will break on refactor.

Test: "Will this comment still be 100% accurate if someone renames the
variables or restructures the loop?" If no, rewrite or delete.

#### Good

```python
# Prices are stored as integer cents to avoid floating-point
# rounding errors in financial calculations.
amount_cents: int
```

```go
// The scheduler distributes work across shards using consistent hashing
// so that rebalancing after a node failure moves minimal keys.
func (s *Scheduler) Assign(key string) *Shard {
```

#### Bad

```python
# Multiply the float price by 100 and cast to int
amount_cents: int
```

```go
// Iterate through the shards array and find the one whose hash range
// contains the murmur3 hash of the key modulo len(shards)
func (s *Scheduler) Assign(key string) *Shard {
```

### 4. The "Why", Never the "What"

Do not repeat the code in English. A comment earns its place only when a
competent developer reading the code would wonder *why* something exists.

#### Good

```python
# Platform API returns paginated results capped at 100. Collect all
# pages to ensure the local cache reflects the full dataset.
while next_cursor:
    page = api.list_users(cursor=next_cursor)
    users.extend(page.results)
    next_cursor = page.next_cursor
```

#### Bad

```python
# Loop through pages and add users to the list
while next_cursor:
    page = api.list_users(cursor=next_cursor)
    users.extend(page.results)
    next_cursor = page.next_cursor
```

### 5. Commit Messages and PR Descriptions Describe the Delta

Temporal language belongs exclusively in git history. This is where you
explain what changed, why it changed, and what it replaces.

#### Good commit message

```
Cap retry limit at 3 to stay within the gateway's 30s timeout

The previous limit of 5 could exceed 30 seconds of total elapsed time
under worst-case backoff, causing the upstream gateway to terminate the
connection before the final attempt completed.
```

#### Good PR description

```markdown
## Summary
Replaces MD5 content hashing with SHA-256 to meet the collision
resistance requirements of the new content-addressed storage layer.

## Context
MD5's known collision vulnerabilities make it unsuitable for
content-addressed storage where hash uniqueness is a correctness
requirement, not just a performance optimization.
```

#### Bad commit message (process leakage that belongs nowhere)

```
Tried a few approaches, settled on SHA-256

First I looked at BLAKE2 but it wasn't in the stdlib. Then I
considered SHA-512 but the output was too long. SHA-256 seems fine.
```

---

## Quick Reference

| Principle | In code comments | In commits/PRs |
|-----------|-----------------|----------------|
| Temporal language ("changed", "fixed", "added") | Never | Always |
| Why the current approach works | Always | Sometimes |
| Why a rejected approach was avoided | Never | When relevant |
| Implementation mechanics | Never | When relevant |
| Business logic / invariants | Always | Summarize |
| References to PRs / tickets | Never | Always |
