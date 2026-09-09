import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { basename } from "node:path";

export default function piAttentionExtension(pi: ExtensionAPI) {
  const pane = process.env.TMUX_PANE;
  const enabled = Boolean(process.env.TMUX && pane);
  let operations = Promise.resolve();

  function enqueue(args: string[]): Promise<void> {
    if (!enabled) return Promise.resolve();

    const operation = operations.then(async () => {
      const result = await pi.exec("pi-attention", args, { timeout: 5000 });
      if (result.code !== 0) {
        throw new Error(result.stderr || `pi-attention exited with ${result.code}`);
      }
    });

    // Attention reporting is advisory and must not interrupt Pi when tmux is
    // unavailable or its server is shutting down.
    operations = operation.catch(() => undefined);
    return operations;
  }

  function register(ctx: ExtensionContext): Promise<void> {
    const sessionFile = ctx.sessionManager.getSessionFile() ?? "";
    const label = pi.getSessionName() ?? "";

    return enqueue([
      "register",
      "--pane",
      pane!,
      "--session-id",
      ctx.sessionManager.getSessionId(),
      "--session-file",
      sessionFile,
      "--project",
      basename(ctx.cwd),
      "--label",
      label,
      "--owner-pid",
      String(process.pid),
    ]);
  }

  pi.on("session_start", async (_event, ctx) => {
    await enqueue(["read", pane!]);
    await register(ctx);
  });

  pi.on("session_info_changed", async (_event, ctx) => {
    await register(ctx);
  });

  pi.on("input", async (event) => {
    if (event.source !== "extension") {
      await enqueue(["read", pane!]);
    }
  });

  pi.on("agent_start", async () => {
    await enqueue(["read", pane!]);
  });

  pi.on("ui_prompt_start", async () => {
    await enqueue(["set", "waiting", pane!]);
    await enqueue(["notify", "waiting", pane!]);
  });

  pi.on("ui_prompt_end", async () => {
    await enqueue(["transition", "waiting", "unread", pane!]);
  });

  pi.on("agent_settled", async () => {
    await enqueue(["set", "unread", pane!]);
    await enqueue(["notify", "unread", pane!]);
  });

  pi.on("session_shutdown", async (event) => {
    if (event.reason === "quit") {
      await enqueue(["unregister", pane!]);
      return;
    }
    await operations;
  });
}
