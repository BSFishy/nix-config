import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

import { MemoryBackendClient } from "./backend";
import { chunkBlocks } from "./chunk";
import { serializeBranchEntries, serializeCompactionMessages } from "./serialize";
import type { MemoryChunk, MemorySource } from "./types";

const backend = new MemoryBackendClient();
let healthChecked = false;

const MEMORY_INJECTION_TOP_K = 5;
const MEMORY_INJECTION_THRESHOLD = 0.35;
const MEMORY_INJECTION_CHAR_BUDGET = 4000;

export default function memoryExtension(pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    await ensureBackendAvailable(ctx);
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
        notify(
          ctx,
          `Memory DB: ${stats.totalMemories} entries (${formatSourceCounts(stats.bySource)}) @ ${stats.databasePath}`,
          "info",
        );
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
        const hits = await backend.search({
          query,
          topK: 5,
          cwd: process.cwd(),
        });

        if (hits.length === 0) {
          notify(ctx, `No memory hits for: ${query}`, "info");
          return;
        }

        const preview = hits
          .map((hit, index) => {
            const snippet = hit.content.replace(/\s+/g, " ").trim().slice(0, 160);
            return `${index + 1}. score=${hit.score.toFixed(3)} source=${hit.source} @ ${hit.createdAt}\n${snippet}`;
          })
          .join("\n\n");

        notify(ctx, `Memory hits for: ${query}\n\n${preview}`, "info");
      } catch (error) {
        notify(ctx, `Memory search failed: ${getErrorMessage(error)}`, "error");
      }
    },
  });
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
