import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { Box, Text } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";

import { MemoryBackendClient } from "./backend";
import { chunkBlocks } from "./chunk";
import { serializeBranchEntries, serializeCompactionMessages } from "./serialize";
import type { MemoryChunk, MemorySearchHit, MemorySource } from "./types";

const backend = new MemoryBackendClient();
let healthChecked = false;

const MEMORY_INJECTION_TOP_K = 5;
const MEMORY_INJECTION_THRESHOLD = 0.35;
const MEMORY_INJECTION_CHAR_BUDGET = 4000;
const MEMORY_SEARCH_DEBUG_MESSAGE_TYPE = "memory-search-debug";
const MEMORY_STATS_MESSAGE_TYPE = "memory-stats";
const MEMORY_CONTEXT_MESSAGE_TYPE = "memory-context";

export default function memoryExtension(pi: ExtensionAPI) {
  let lastSearchHits: MemorySearchHit[] = [];
  let lastSearchQuery = "";

  pi.registerMessageRenderer(MEMORY_SEARCH_DEBUG_MESSAGE_TYPE, (message, { expanded }, theme) => {
    const details = message.details as { query?: string; hitCount?: number } | undefined;
    const title = theme.fg("accent", "[memory-search]");
    let text = `${title} ${message.content}`;

    if (expanded && details) {
      text += `\n${theme.fg("dim", `query=${details.query ?? ""} hits=${details.hitCount ?? 0}`)}`;
    }

    const box = new Box(1, 1, (t) => theme.bg("customMessageBg", t));
    box.addChild(new Text(text, 0, 0));
    return box;
  });

  pi.registerMessageRenderer(MEMORY_STATS_MESSAGE_TYPE, (message, { expanded }, theme) => {
    const details = message.details as { databasePath?: string; bySource?: Record<string, number> } | undefined;
    const title = theme.fg("accent", "[memory-stats]");
    let text = `${title} ${message.content}`;

    if (expanded && details) {
      text += `\n${theme.fg("dim", `db=${details.databasePath ?? ""}`)}`;
      const sourceCounts = details.bySource ? formatSourceCounts(details.bySource) : "no sources yet";
      text += `\n${theme.fg("dim", `sources=${sourceCounts}`)}`;
    }

    const box = new Box(1, 1, (t) => theme.bg("customMessageBg", t));
    box.addChild(new Text(text, 0, 0));
    return box;
  });

  pi.registerMessageRenderer(MEMORY_CONTEXT_MESSAGE_TYPE, (message, { expanded }, theme) => {
    const details = message.details as { query?: string; index?: number; source?: string; score?: number } | undefined;
    const title = theme.fg("accent", "[memory-context]");
    let text = `${title} ${message.content}`;

    if (expanded && details) {
      text += `\n${theme.fg("dim", `query=${details.query ?? ""} index=${details.index ?? 0} source=${details.source ?? ""} score=${typeof details.score === "number" ? details.score.toFixed(3) : ""}`)}`;
    }

    const box = new Box(1, 1, (t) => theme.bg("customMessageBg", t));
    box.addChild(new Text(text, 0, 0));
    return box;
  });

  pi.on("session_start", async (_event, ctx) => {
    await ensureBackendAvailable(ctx);
  });

  pi.on("context", async (event) => {
    return {
      messages: event.messages.filter((message) => {
        const candidate = message as { customType?: string };
        return candidate.customType !== MEMORY_SEARCH_DEBUG_MESSAGE_TYPE && candidate.customType !== MEMORY_STATS_MESSAGE_TYPE && candidate.customType !== MEMORY_CONTEXT_MESSAGE_TYPE;
      }),
    };
  });

  pi.on("before_agent_start", async (event, ctx) => {
    if (!(await ensureBackendAvailable(ctx))) return;

    try {
      const hits = await backend.search({
        query: event.prompt,
        topK: MEMORY_INJECTION_TOP_K,
        threshold: MEMORY_INJECTION_THRESHOLD,
        cwd: process.cwd(),
      });

      if (hits.length === 0) {
        return;
      }

      const injected = fitHitsToBudget(hits, MEMORY_INJECTION_CHAR_BUDGET);
      if (injected.length === 0) {
        return;
      }

      notify(
        ctx,
        `Injecting ${injected.length} memory hit${injected.length === 1 ? "" : "s"} (${injected
          .map((hit) => `${hit.source}:${hit.score.toFixed(3)}`)
          .join(", ")})`,
        "info",
      );

      const memoryBlock = injected
        .map((hit, index) => {
          const snippet = hit.content.trim();
          return `[${index + 1}] score=${hit.score.toFixed(3)} source=${hit.source} created_at=${hit.createdAt}\n${snippet}`;
        })
        .join("\n\n---\n\n");

      return {
        systemPrompt:
          `${event.systemPrompt}\n\n## Relevant Context from Past Sessions\n` +
          `The following are excerpts from previous Pi sessions that may be relevant to the current request. ` +
          `Use them as hints, but still verify repository facts against actual files, commands, and docs before making claims.\n\n` +
          memoryBlock,
      };
    } catch (error) {
      notify(ctx, `Memory injection failed: ${getErrorMessage(error)}`, "warning");
      return;
    }
  });

  pi.on("session_before_compact", async (event, ctx) => {
    if (!(await ensureBackendAvailable(ctx))) return;

    const { preparation, signal } = event;
    const blocks = serializeCompactionMessages(
      preparation.messagesToSummarize,
      preparation.previousSummary,
    );

    await persistBlocks({
      pi,
      ctx,
      source: "compaction",
      blocks,
      metadata: {
        previousSummary: preparation.previousSummary,
        messageCount: preparation.messagesToSummarize.length,
        tokensBefore: preparation.tokensBefore,
        firstKeptEntryId: preparation.firstKeptEntryId,
      },
      signal,
    });
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    try {
      if (!backend.isConfigured()) return;

      const branchEntries = ctx.sessionManager.getBranch();
      const blocks = serializeBranchEntries(branchEntries);

      await persistBlocks({
        pi,
        ctx,
        source: "session_end",
        blocks,
        metadata: {
          messageCount: branchEntries.length,
        },
      });
    } finally {
      healthChecked = false;
      await backend.dispose();
    }
  });

  pi.registerCommand("memory-stats", {
    description: "Show Pi memory backend stats",
    handler: async (_args, ctx) => {
      if (!(await ensureBackendAvailable(ctx))) return;

      try {
        const stats = await backend.stats();
        pi.sendMessage({
          customType: MEMORY_STATS_MESSAGE_TYPE,
          content: `Memory DB: ${stats.totalMemories} entries (${formatSourceCounts(stats.bySource)}) @ ${stats.databasePath}`,
          display: true,
          details: {
            databasePath: stats.databasePath,
            bySource: stats.bySource,
            totalMemories: stats.totalMemories,
          },
        });
      } catch (error) {
        notify(ctx, `Failed to query memory stats: ${getErrorMessage(error)}`, "error");
      }
    },
  });

  pi.registerCommand("memory-save", {
    description: "Manually persist the current session branch via the Pi memory backend",
    handler: async (_args, ctx) => {
      if (!(await ensureBackendAvailable(ctx))) return;

      const branchEntries = ctx.sessionManager.getBranch();
      const blocks = serializeBranchEntries(branchEntries);
      const inserted = await persistBlocks({
        pi,
        ctx,
        source: "manual",
        blocks,
        metadata: {
          messageCount: branchEntries.length,
        },
      });

      notify(ctx, `Saved ${inserted} memory chunk${inserted === 1 ? "" : "s"}.`, "info");
    },
  });

  pi.registerCommand("memory-search", {
    description: "Search the Pi memory backend: /memory-search <query>",
    handler: async (args, ctx) => {
      if (!(await ensureBackendAvailable(ctx))) return;

      const query = args.trim();
      if (!query) {
        notify(ctx, "Usage: /memory-search <query>", "warning");
        return;
      }

      try {
        const hits = await runMemorySearch(query);
        showMemorySearchMessage(pi, query, hits);
      } catch (error) {
        notify(ctx, `Memory search failed: ${getErrorMessage(error)}`, "error");
      }
    },
  });

  pi.registerCommand("memory-context", {
    description: "Show the full saved context for a hit from the last /memory-search: /memory-context <index>",
    handler: async (args, ctx) => {
      if (!(await ensureBackendAvailable(ctx))) return;

      const index = Number.parseInt(args.trim(), 10);
      if (!Number.isInteger(index) || index < 1) {
        notify(ctx, "Usage: /memory-context <index> (from the last /memory-search)", "warning");
        return;
      }

      const hit = getLastSearchHit(index);
      if (!hit) {
        if (lastSearchHits.length === 0) {
          notify(ctx, "No recent /memory-search results. Run /memory-search <query> first.", "warning");
        } else {
          notify(ctx, `Hit ${index} does not exist. Last search returned ${lastSearchHits.length} hit${lastSearchHits.length === 1 ? "" : "s"}.`, "warning");
        }
        return;
      }

      showMemoryContextMessage(pi, lastSearchQuery, index, hit);
    },
  });

  pi.registerTool({
    name: "memory_search",
    label: "Memory Search",
    description: "Search the Pi memory backend for relevant saved conversation context.",
    promptSnippet: "Search saved Pi memory entries by semantic query and return ranked hits.",
    promptGuidelines: [
      "Use memory_search when the user asks about prior sessions, earlier decisions, or saved context that may not be in the current conversation.",
      "Use memory_context after memory_search when you need the full saved text of a specific hit before citing or relying on it.",
      "Treat memory_search hits as hints and verify repository facts against files, commands, or docs before making project claims.",
    ],
    parameters: Type.Object({
      query: Type.String({ description: "Semantic search query for saved memory" }),
      topK: Type.Optional(Type.Number({ description: "Maximum number of hits to return", minimum: 1, maximum: 20 })),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      if (!(await ensureBackendAvailable(ctx))) {
        return {
          content: [{ type: "text", text: "Pi memory backend is not available." }],
          details: { ok: false },
        };
      }

      const hits = await runMemorySearch(params.query, params.topK ?? 5);

      if (hits.length === 0) {
        return {
          content: [{ type: "text", text: `No memory hits for: ${params.query}` }],
          details: { query: params.query, hitCount: 0, hits: [] },
        };
      }

      const summary = hits
        .map((hit, index) => {
          const snippet = hit.content.replace(/\s+/g, " ").trim().slice(0, 160);
          return `${index + 1}. score=${hit.score.toFixed(3)} source=${hit.source} @ ${hit.createdAt}\n${snippet}`;
        })
        .join("\n\n");

      return {
        content: [{ type: "text", text: `Memory search for: ${params.query}\n\n${summary}` }],
        details: { query: params.query, hitCount: hits.length, hits },
      };
    },
  });

  pi.registerTool({
    name: "memory_context",
    label: "Memory Context",
    description: "Show the full saved memory text for a hit from the most recent memory search.",
    promptSnippet: "Expand a hit from the most recent memory search into its full saved context.",
    promptGuidelines: [
      "Use memory_context after memory_search when a short preview is not enough and you need the full saved text for one hit.",
      "Pass the 1-based hit index from the most recent memory_search result.",
      "Prefer reading full memory_context output before quoting or depending on a memory hit in your answer.",
    ],
    parameters: Type.Object({
      index: Type.Number({ description: "1-based hit index from the most recent memory_search result", minimum: 1 }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      if (!(await ensureBackendAvailable(ctx))) {
        return {
          content: [{ type: "text", text: "Pi memory backend is not available." }],
          details: { ok: false },
        };
      }

      const hit = getLastSearchHit(params.index);
      if (!hit) {
        const message =
          lastSearchHits.length === 0
            ? "No recent memory_search results. Run memory_search first."
            : `Hit ${params.index} does not exist. Last search returned ${lastSearchHits.length} hit${lastSearchHits.length === 1 ? "" : "s"}.`;
        return {
          content: [{ type: "text", text: message }],
          details: { ok: false, index: params.index, availableHits: lastSearchHits.length },
        };
      }

      const fullContext = formatMemoryContext(params.index, hit);
      return {
        content: [{ type: "text", text: `Full context for hit ${params.index} from search: ${lastSearchQuery}\n\n${fullContext}` }],
        details: { ok: true, query: lastSearchQuery, index: params.index, hit },
      };
    },
  });

  pi.registerTool({
    name: "memory_save",
    label: "Memory Save",
    description: "Persist the current session branch into the Pi memory backend.",
    promptSnippet: "Save the current Pi session branch into long-term memory chunks.",
    promptGuidelines: [
      "Use memory_save when the user explicitly asks to save important session context into memory.",
      "Do not call memory_save routinely unless the user requests persistence or the workflow clearly benefits from saving state.",
      "memory_save saves the current branch only; it does not search or retrieve memories.",
    ],
    parameters: Type.Object({}),
    async execute(_toolCallId, _params, _signal, _onUpdate, ctx) {
      if (!(await ensureBackendAvailable(ctx))) {
        return {
          content: [{ type: "text", text: "Pi memory backend is not available." }],
          details: { ok: false },
        };
      }

      const branchEntries = ctx.sessionManager.getBranch();
      const blocks = serializeBranchEntries(branchEntries);
      const inserted = await persistBlocks({
        pi,
        ctx,
        source: "manual",
        blocks,
        metadata: {
          messageCount: branchEntries.length,
        },
      });

      return {
        content: [{ type: "text", text: `Saved ${inserted} memory chunk${inserted === 1 ? "" : "s"}.` }],
        details: { ok: true, inserted, messageCount: branchEntries.length },
      };
    },
  });

  async function runMemorySearch(query: string, topK = 5): Promise<MemorySearchHit[]> {
    const hits = await backend.search({
      query,
      topK,
      cwd: process.cwd(),
    });

    lastSearchQuery = query;
    lastSearchHits = hits;
    return hits;
  }

  function showMemorySearchMessage(pi: ExtensionAPI, query: string, hits: MemorySearchHit[], topK = 5): void {
    if (hits.length === 0) {
      pi.sendMessage({
        customType: MEMORY_SEARCH_DEBUG_MESSAGE_TYPE,
        content: `Memory search for: ${query}\n\nNo hits.`,
        display: true,
        details: { query, hitCount: 0, cwd: process.cwd(), topK },
      });
      return;
    }

    const preview = hits
      .map((hit, index) => {
        const snippet = hit.content.replace(/\s+/g, " ").trim().slice(0, 160);
        return `${index + 1}. score=${hit.score.toFixed(3)} source=${hit.source} @ ${hit.createdAt}\n${snippet}`;
      })
      .join("\n\n");

    pi.sendMessage({
      customType: MEMORY_SEARCH_DEBUG_MESSAGE_TYPE,
      content: `Memory search for: ${query}\n\n${preview}`,
      display: true,
      details: {
        query,
        hitCount: hits.length,
        cwd: process.cwd(),
        topK,
      },
    });
  }

  function getLastSearchHit(index: number): MemorySearchHit | undefined {
    return lastSearchHits[index - 1];
  }

  function formatMemoryContext(index: number, hit: MemorySearchHit): string {
    return `[${index}] score=${hit.score.toFixed(3)} source=${hit.source} created_at=${hit.createdAt}\n${hit.content.trim()}`;
  }

  function showMemoryContextMessage(pi: ExtensionAPI, query: string, index: number, hit: MemorySearchHit): void {
    pi.sendMessage({
      customType: MEMORY_CONTEXT_MESSAGE_TYPE,
      content: `Full context for hit ${index} from search: ${query}\n\n${formatMemoryContext(index, hit)}`,
      display: true,
      details: {
        query,
        index,
        source: hit.source,
        score: hit.score,
        createdAt: hit.createdAt,
        sessionFile: hit.sessionFile,
        cwd: hit.cwd,
      },
    });
  }
}

async function ensureBackendAvailable(ctx: ExtensionContext): Promise<boolean> {
  if (!backend.isConfigured()) {
    notify(ctx, "Pi memory backend path is not configured.", "warning");
    return false;
  }

  if (healthChecked) return true;

  const result = await backend.health();
  if (!result.ok) {
    notify(ctx, `Pi memory backend unavailable: ${result.error}`, "warning");
    return false;
  }

  healthChecked = true;
  notify(ctx, `Pi memory backend ready: ${backend.getBackendPath()}`, "info");
  return true;
}

async function persistBlocks({
  pi,
  ctx,
  source,
  blocks,
  metadata,
  signal,
}: {
  pi: ExtensionAPI;
  ctx: ExtensionContext;
  source: MemorySource;
  blocks: string[];
  metadata?: Record<string, unknown>;
  signal?: AbortSignal;
}): Promise<number> {
  const sessionFile = ctx.sessionManager.getSessionFile() ?? undefined;
  const leafId = ctx.sessionManager.getLeafId();
  const cwd = process.cwd();
  const gitBranch = await getGitBranch(pi);
  const sessionKey = sessionFile ?? `ephemeral:${cwd}`;
  const createdAt = new Date().toISOString();
  const chunks = chunkBlocks(blocks);
  const payloadChunks: MemoryChunk[] = [];

  for (const [ chunkIndex, chunk ] of chunks.entries()) {
    if (signal?.aborted) break;
    if (!chunk.trim()) continue;

    payloadChunks.push({
      content: chunk,
      createdAt,
      metadata: {
        ...metadata,
        sessionFile,
        leafId,
        savedAt: createdAt,
        chunkIndex,
        chunkCount: chunks.length,
      },
    });
  }

  if (payloadChunks.length === 0) {
    return 0;
  }

  try {
    const result = await backend.save({
      source,
      sessionKey,
      sessionFile,
      cwd,
      gitBranch,
      leafId,
      chunks: payloadChunks,
      metadata,
    });

    if (result.inserted > 0) {
      notify(ctx, `Persisted ${result.inserted} ${source} memory chunk${result.inserted === 1 ? "" : "s"}.`, "info");
    }

    return result.inserted;
  } catch (error) {
    notify(ctx, `Failed to persist ${source} memory chunks: ${getErrorMessage(error)}`, "error");
    return 0;
  }
}

async function getGitBranch(pi: ExtensionAPI): Promise<string | undefined> {
  const { stdout, code } = await pi.exec("git", [ "branch", "--show-current" ]);
  if (code !== 0) return undefined;
  const branch = stdout.trim();
  return branch || undefined;
}

function formatSourceCounts(counts: Record<string, number>): string {
  const entries = Object.entries(counts);
  if (entries.length === 0) return "no sources yet";
  return entries.map(([ source, count ]) => `${source}: ${count}`).join(", ");
}

function fitHitsToBudget<T extends { content: string }>(hits: T[], maxChars: number): T[] {
  const fitted: T[] = [];
  let used = 0;

  for (const hit of hits) {
    const cost = hit.content.length;
    if (fitted.length > 0 && used + cost > maxChars) {
      break;
    }
    if (cost > maxChars && fitted.length === 0) {
      fitted.push({
        ...hit,
        content: hit.content.slice(0, maxChars),
      });
      break;
    }

    fitted.push(hit);
    used += cost;
  }

  return fitted;
}

function notify(ctx: ExtensionContext, message: string, level: "info" | "warning" | "error"): void {
  if (ctx.hasUI) {
    ctx.ui.notify(message, level);
  }
}

function getErrorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
