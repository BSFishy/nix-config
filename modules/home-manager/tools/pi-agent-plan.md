# Pi Coding Agent — Memory Extension Plan

## Overview

Set up [Pi](https://github.com/badlogic/pi-mono) (`@mariozechner/pi-coding-agent`)
as the primary coding agent, managed via home-manager. Build a local-first memory
extension that reduces hallucination by (a) enforcing tool-check discipline,
(b) persisting session knowledge, and (c) automatically injecting relevant past
context before the LLM starts thinking.

The core insight: the biggest source of hallucination isn't missing memory — it's
the LLM not using the resources it already has. A memory system helps, but only
on top of prompting discipline and automatic context injection. Layers 1-3 below
are ordered by impact-per-effort. Layer 4 (research-backed sophistication) is
deferred until real failure modes emerge from using layers 1-3.

Research basis: the `agentic-memory` repo (Leonard Lin) surveys 48 references
and 18+ systems. Key finding: don't over-engineer extraction. Store raw text,
embed it, retrieve it. Add sophistication only where it demonstrably helps.

---

## Layer 1: System Prompt Discipline

**Goal:** Tell the model to check tools/docs/files before making claims.

**Mechanism:** Pi extensions can register tools with `promptGuidelines` — an
array of strings that get injected as bullet points into the `Guidelines:`
section of the system prompt. Only guidelines from *active* tools are included.
The flow is:

1. Tool registered with `pi.registerTool({ promptGuidelines: [...] })`
2. Guidelines normalized (trimmed, deduped) and stored in a Map keyed by tool
   name (`agent-session.ts:2266-2273`)
3. On each prompt, `_rebuildSystemPrompt` collects guidelines from active tools
   only (`agent-session.ts:884-917`)
4. `buildSystemPrompt` injects them as `- bullet` items in the `Guidelines:`
   section (`system-prompt.ts:118-123`), deduped via a Set

So registering a tool (even a no-op tool) with `promptGuidelines` is the
simplest way to inject behavioral instructions into every prompt.

**Additionally**, the `before_agent_start` event fires after the user submits a
prompt but before the LLM sees anything. An extension can return a modified
`systemPrompt` string:

```typescript
pi.on("before_agent_start", async (event, ctx) => {
  return {
    systemPrompt: event.systemPrompt + "\n\n## Memory & Verification Rules\n..."
  };
});
```

This chains across extensions — each handler receives the current (possibly
already modified) system prompt.

**What to inject (draft guidelines):**

```typescript
promptGuidelines: [
  "NEVER answer factual questions about the project from memory alone. Always read the relevant file or run the relevant command first.",
  "When asked about code structure, dependencies, or configuration, use read/grep/find to verify before responding.",
  "If you are uncertain about any claim, say so and offer to look it up rather than guessing.",
  "Prefer checking docs/ and README files over inferring behavior from code.",
  "When referencing previous conversations or decisions, use the memory_search tool to retrieve actual records.",
]
```

**Complexity:** Trivial. This is a string array on a tool registration.

---

## Layer 2: Session Persistence to Local SQLite

**Goal:** After each session (or before compaction), save conversation content to
a local SQLite database with vector embeddings for later retrieval.

**Storage stack:**
- `better-sqlite3` — SQLite from Node.js (npm dependency in the extension)
- `sqlite-vec` — vector similarity search extension for SQLite
  (or alternatively, compute cosine similarity in JS over stored float arrays)
- Embedding model: `all-MiniLM-L6-v2` via `@xenova/transformers` (runs 100%
  locally in Node.js, no API keys, ~80MB model, fast on CPU)

**Database location:** `~/.pi/agent/memory.db` (persists across all sessions)

**Schema (draft):**

```sql
CREATE TABLE memories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT NOT NULL,          -- pi session identifier
  created_at TEXT NOT NULL,          -- ISO timestamp
  content TEXT NOT NULL,             -- the raw text (conversation chunk, summary, etc.)
  source TEXT NOT NULL,              -- 'session_end' | 'compaction' | 'manual' | 'tool'
  embedding BLOB NOT NULL,          -- float32 vector from MiniLM
  metadata TEXT                     -- JSON blob for extra context (cwd, branch, files touched, etc.)
);

CREATE INDEX idx_memories_session ON memories(session_id);
CREATE INDEX idx_memories_created ON memories(created_at);
```

If using `sqlite-vec`:
```sql
CREATE VIRTUAL TABLE memory_vectors USING vec0(
  id INTEGER PRIMARY KEY,
  embedding float[384]              -- MiniLM-L6-v2 outputs 384-dim vectors
);
```

**Extraction hooks:**

1. **`session_before_compact`** — Fires right before compaction discards older
   messages. The event provides `preparation.messagesToSummarize` — the messages
   about to be lost. Extract and embed them before they're gone:

   ```typescript
   pi.on("session_before_compact", async (event, ctx) => {
     const text = serializeMessages(event.preparation.messagesToSummarize);
     const embedding = await embed(text);
     db.insertMemory({ content: text, embedding, source: "compaction", ... });
   });
   ```

2. **`session_shutdown`** — Fires on session exit. Serialize the current
   branch's conversation and save a summary:

   ```typescript
   pi.on("session_shutdown", async (_event, ctx) => {
     const branch = ctx.sessionManager.getBranch();
     const text = serializeBranch(branch);
     const embedding = await embed(text);
     db.insertMemory({ content: text, embedding, source: "session_end", ... });
   });
   ```

3. **`turn_end`** — Optionally extract after each turn for more granular memory.
   This is higher write volume but gives finer-grained retrieval later.

**Chunking strategy:** Don't store entire sessions as single documents. Chunk by
turn or by logical segment (a few turns that discuss one topic). Smaller chunks
retrieve more precisely. A reasonable starting point is one memory entry per
assistant turn (the user message + assistant response + any tool calls/results).

**No LLM required in the write path.** The extraction is just serialization +
embedding. No summarization, no entity extraction, no knowledge graph
construction. Keep it simple. The raw text with embeddings is the baseline that
the research says works surprisingly well.

**Complexity:** Medium. Main effort is wiring up the SQLite + embedding pipeline
and getting the chunking right.

---

## Layer 3: Automatic Context Retrieval & Injection

**Goal:** Before the LLM starts processing each prompt, automatically retrieve
relevant past context from the memory database and inject it into the prompt so
the model doesn't need to decide to look things up.

### How retrieval works

**Yes, you query the SQLite db using the user's prompt as the query — but not as
a text match. Here's the actual flow:**

1. User types a prompt (e.g. "why is the auth middleware failing?")
2. The `before_agent_start` event fires. Your extension receives `event.prompt`
   (the raw user text)
3. You run `event.prompt` through the same embedding model (all-MiniLM-L6-v2)
   to get a query vector
4. You query `sqlite-vec` for the top-k nearest neighbors by cosine similarity
   against all stored memory embeddings
5. The returned memories are the ones whose *meaning* is closest to the user's
   current question — not keyword matching, but semantic similarity
6. You inject the top-k results into the system prompt (or as an invisible
   message)

```typescript
pi.on("before_agent_start", async (event, ctx) => {
  // Step 1: embed the user's prompt
  const queryEmbedding = await embed(event.prompt);

  // Step 2: retrieve top-k semantically similar memories
  const memories = db.query(`
    SELECT m.content, m.created_at, m.metadata,
           vec_distance_cosine(v.embedding, ?) AS distance
    FROM memories m
    JOIN memory_vectors v ON m.id = v.id
    ORDER BY distance ASC
    LIMIT ?
  `, [queryEmbedding, TOP_K]);

  // Step 3: check context budget before injecting
  const usage = ctx.getContextUsage();
  const budgetTokens = 4000; // reserve this many tokens for memory
  const injected = fitToBudget(memories, budgetTokens);

  // Step 4: inject into system prompt
  if (injected.length > 0) {
    const memoryBlock = injected
      .map(m => `[${m.created_at}] ${m.content}`)
      .join("\n---\n");

    return {
      systemPrompt: event.systemPrompt +
        `\n\n## Relevant Context from Past Sessions\n` +
        `The following are excerpts from previous conversations that may be ` +
        `relevant to the current request. Use them as reference but verify ` +
        `details against actual files/code.\n\n` +
        memoryBlock,
    };
  }
});
```

### Why this works (and why it's not just grep)

Semantic embeddings map text to a high-dimensional vector space where meaning is
preserved. "auth middleware failing" and "the authentication layer throws a 401
error when the JWT token expires" have high cosine similarity even though they
share almost no keywords. This is fundamentally different from grep/keyword
search — it finds things by *what they mean*, not by *what words they use*.

The all-MiniLM-L6-v2 model is specifically trained for semantic similarity. It
runs locally, needs no API key, and inference is fast (~5-10ms per embedding on
CPU).

### Retrieval quality knobs

- **Top-K**: Start with k=5. Too many results dilute relevance and eat context
  budget. Too few miss useful context.
- **Distance threshold**: Discard results above a certain distance (e.g. >0.7).
  If nothing is close enough, inject nothing — don't force irrelevant context.
- **Recency bias**: Optionally weight results by age. A simple approach:
  `final_score = similarity * exp(-lambda * days_old)` where lambda controls how
  fast old memories decay. This is the "memory decay" concept from the research
  (Mnemosyne, Memoria) without needing a complex system.
- **Token budget**: Use `ctx.getContextUsage()` to check how much room you have.
  Don't inject 10k tokens of memories into a 128k context that's already 120k
  full. Reserve a fixed budget (e.g. 4000 tokens) and truncate/skip if needed.

### Hybrid retrieval (optional enhancement)

sqlite-vec gives you vector (semantic) search. SQLite's built-in FTS5 gives you
keyword (BM25) search. Combining both with Reciprocal Rank Fusion (RRF) is a
well-studied technique that improves recall:

```sql
-- FTS5 table for keyword search
CREATE VIRTUAL TABLE memory_fts USING fts5(content, content='memories', content_rowid='id');
```

```typescript
// Query both, fuse with RRF
const vecResults = db.vectorSearch(queryEmbedding, k * 2);
const ftsResults = db.ftsSearch(event.prompt, k * 2);
const fused = reciprocalRankFusion(vecResults, ftsResults, k);
```

This handles the case where the user asks something with specific terms that
embeddings might miss (e.g. exact error codes, package names, file paths).

**Complexity:** The basic version (embed prompt → top-k → inject) is simple.
Adding distance thresholds, recency decay, and hybrid retrieval is incremental.

---

## Layer 4: Research-Backed Enhancements (Deferred)

These are NOT part of the initial build. They're documented here so we know what
to reach for when specific failure modes emerge from using layers 1-3.

### When memories get stale/contradictory → Nemori predict-calibrate
- Paper: arxiv:2508.03341
- Only store what the system *failed to predict* from existing knowledge
- Prevents memory bloat from repetitive sessions (same build errors, same patterns)
- Requires LLM calls on the write path (local LLM via ollama)

### When you need temporal reasoning → Zep/Graphiti bi-temporal validity
- Paper: arxiv:2501.13956
- Facts have `valid_at`/`invalid_at` (when the fact was true) and
  `created_at`/`expired_at` (when the system learned/forgot it)
- Handles "project X used framework Y from Jan to March, then switched to Z"
- `memv` (pip: memvee) implements this on SQLite — could be a reference

### When you need relationship/pattern discovery → Karta dream engine
- Source: github.com/rohithzr/karta (MIT, Rust)
- Background inference: deduction, induction, abduction, contradiction detection
- Requires LLM calls (local LLM via ollama on homelab)
- Fun but high complexity

### When you need hierarchical time-based rollups → TiMem
- Paper: arxiv:2601.02845
- Best benchmark numbers (LoCoMo 75.30%, LongMemEvalS 78.96%)
- Consolidates: turn → session → daily → weekly → profile
- Good for long-running projects

### When you need typed memory stores → ENGRAM
- Paper: arxiv:2511.12960
- Episodic / semantic / procedural stores with a small router
- Ablation shows typed stores crush single store (77.55% vs 46.56%)
- Low complexity, high impact — likely the first Layer 4 enhancement to add

---

## Extension Structure (Draft)

```
~/.pi/agent/extensions/memory/
├── package.json          # deps: better-sqlite3, @xenova/transformers, sqlite-vec
├── index.ts              # main extension entry point
├── db.ts                 # SQLite schema, migrations, query helpers
├── embedder.ts           # MiniLM embedding wrapper (lazy-loads model on first use)
├── retriever.ts          # top-k retrieval with distance threshold + recency decay
├── injector.ts           # formats memories for system prompt injection
└── tools.ts              # memory_search, memory_save, memory_forget tool defs
```

**Custom tools to register:**
- `memory_search` — explicit search (so the LLM can query memory when it wants)
- `memory_save` — explicit save (so the LLM can note something important)
- `memory_forget` — explicit delete (so the LLM or user can remove bad memories)

These complement the automatic extraction/injection — the auto system handles
background memory, the tools let the LLM and user manage memory explicitly.

---

## Home-Manager Integration

TODO: Add Pi installation and extension configuration to the home-manager setup.
This will involve:

- [ ] Install Pi via npm/nix
- [ ] Set up the extension directory structure
- [ ] Install extension npm dependencies (better-sqlite3, @xenova/transformers)
- [ ] Ensure the MiniLM model is downloaded on first run
- [ ] Configure Pi settings (model, provider, etc.)
- [ ] Wire up the AGENTS.md / context files for projects

---

## Open Questions

1. **Chunking granularity**: One memory per turn? Per topic segment? Per session?
   Start with per-turn and see how retrieval quality feels.
2. **Memory cap**: Should old memories be pruned? Or does the distance threshold
   naturally handle irrelevant old stuff? Start without pruning, revisit if the
   db gets huge.
3. **Multi-project isolation**: Should memories be scoped per-project (by cwd)?
   Probably yes — include cwd in metadata and filter on retrieval.
4. **Embedding model**: all-MiniLM-L6-v2 is the default choice. Could upgrade to
   a larger model (e.g. `all-mpnet-base-v2`, 768-dim) if 384-dim isn't precise
   enough. Trade-off is speed and storage.
5. **What to do during compaction**: Save the raw messages? A summary? Both? Start
   with raw messages (research says raw outperforms extraction). Add summaries
   later if raw chunks are too noisy at retrieval time.
