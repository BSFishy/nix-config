# pi-memory-backend

Rust backend for the Pi memory extension.

## Intended role

This binary is intended to run as a long-lived subprocess started by the Pi
TypeScript extension. The extension communicates with it over newline-delimited
JSON on stdin/stdout.

## Planned responsibilities

- SQLite schema and migrations
- Embedding generation via `ort`
- Memory persistence and retrieval
- Future Layer 4 memory logic

## Current state

This is currently only a scaffold. It implements the stdio request loop and
returns placeholder responses for `health`, `stats`, and `save`.
