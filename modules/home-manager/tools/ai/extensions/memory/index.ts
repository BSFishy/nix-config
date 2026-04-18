import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

import { MemoryBackendClient } from "./backend";
import { chunkBlocks } from "./chunk";
import { serializeBranchEntries, serializeCompactionMessages } from "./serialize";
import type { MemoryChunk, MemorySource } from "./types";

const backend = new MemoryBackendClient();
let healthChecked = false;

export default function memoryExtension(pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    await ensureBackendAvailable(ctx);
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

function notify(ctx: ExtensionContext, message: string, level: "info" | "warning" | "error"): void {
  if (ctx.hasUI) {
    ctx.ui.notify(message, level);
  }
}

function getErrorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
