import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";

import type {
  MemoryBackendRequest,
  MemoryBackendResponse,
  MemoryStats,
  SaveMemoryPayload,
} from "./types";

const CONFIGURED_BACKEND_PATH = process.env.PI_MEMORY_BACKEND || "__PI_MEMORY_BACKEND__";

interface PendingRequest {
  resolve: (response: MemoryBackendResponse) => void;
  reject: (error: Error) => void;
}

export class MemoryBackendClient {
  private child?: ChildProcessWithoutNullStreams;
  private startPromise?: Promise<ChildProcessWithoutNullStreams>;
  private stdoutBuffer = "";
  private nextRequestId = 1;
  private readonly pending = new Map<string, PendingRequest>();

  constructor(private readonly backendPath = CONFIGURED_BACKEND_PATH) {}

  isConfigured(): boolean {
    // separate the string here so it doesnt get find & replace when building
    // the package
    return Boolean(this.backendPath) && this.backendPath !== "__PI_MEMORY" + "_BACKEND__";
  }

  getBackendPath(): string {
    return this.backendPath;
  }

  async health(): Promise<{ ok: true } | { ok: false; error: string }> {
    const response = await this.request({ type: "health" });
    return response.ok ? { ok: true } : { ok: false, error: response.error };
  }

  async save(payload: SaveMemoryPayload): Promise<{ inserted: number; skipped: number }> {
    // @ts-ignore: get a clue man
    const response = await this.request({ type: "save", payload });
    if (!response.ok) {
      throw new Error(response.error);
    }

    const result = response.result;
    if (!isSaveResult(result)) {
      throw new Error("Memory backend returned an unexpected save result");
    }

    return result;
  }

  async stats(): Promise<MemoryStats> {
    const response = await this.request({ type: "stats" });
    if (!response.ok) {
      throw new Error(response.error);
    }

    const result = response.result;
    if (!isMemoryStats(result)) {
      throw new Error("Memory backend returned an unexpected stats result");
    }

    return result;
  }

  async dispose(): Promise<void> {
    const child = this.child;
    this.child = undefined;
    this.startPromise = undefined;
    this.stdoutBuffer = "";

    if (!child) return;

    for (const [ id, pending ] of this.pending.entries()) {
      pending.reject(new Error(`Memory backend disposed while request ${id} was pending`));
    }
    this.pending.clear();

    await new Promise<void>((resolve) => {
      let settled = false;

      const finish = () => {
        if (settled) return;
        settled = true;
        resolve();
      };

      child.once("close", () => finish());
      child.once("error", () => finish());

      if (!child.killed) {
        child.kill();
        setTimeout(() => {
          if (!settled && !child.killed) {
            child.kill("SIGKILL");
          }
          finish();
        }, 1000).unref();
      } else {
        finish();
      }
    });
  }

  private async request(request: Omit<MemoryBackendRequest, "id">): Promise<MemoryBackendResponse> {
    if (!this.isConfigured()) {
      return {
        id: "unconfigured",
        ok: false,
        error: "PI memory backend path is not configured",
      };
    }

    const child = await this.ensureStarted();
    const id = String(this.nextRequestId++);
    const requestWithId = { ...request, id } as MemoryBackendRequest;

    return await new Promise<MemoryBackendResponse>((resolve, reject) => {
      this.pending.set(id, { resolve, reject });

      try {
        child.stdin.write(`${JSON.stringify(requestWithId)}\n`, (error) => {
          if (error) {
            this.pending.delete(id);
            reject(error instanceof Error ? error : new Error(String(error)));
          }
        });
      } catch (error) {
        this.pending.delete(id);
        reject(error instanceof Error ? error : new Error(String(error)));
      }
    });
  }

  private async ensureStarted(): Promise<ChildProcessWithoutNullStreams> {
    if (this.child && !this.child.killed) {
      return this.child;
    }

    if (!this.startPromise) {
      this.startPromise = this.start();
    }

    try {
      return await this.startPromise;
    } finally {
      this.startPromise = undefined;
    }
  }

  private async start(): Promise<ChildProcessWithoutNullStreams> {
    return await new Promise<ChildProcessWithoutNullStreams>((resolve, reject) => {
      const child = spawn(this.backendPath, [], {
        stdio: [ "pipe", "pipe", "pipe" ],
      });

      child.stdout.setEncoding("utf8");
      child.stderr.setEncoding("utf8");

      let stderr = "";
      let started = false;

      child.stdout.on("data", (chunk) => {
        this.stdoutBuffer += chunk;
        this.processStdoutBuffer();
      });

      child.stderr.on("data", (chunk) => {
        stderr += chunk;
      });

      child.once("spawn", () => {
        started = true;
        this.child = child;
        resolve(child);
      });

      child.once("error", (error) => {
        if (!started) {
          reject(error);
          return;
        }

        this.handleChildTermination(error);
      });

      child.once("close", (code, signal) => {
        const message = stderr.trim() || `memory backend exited with code ${code ?? "unknown"}${signal ? ` (signal ${signal})` : ""}`;
        const error = new Error(message);

        if (!started) {
          reject(error);
          return;
        }

        this.handleChildTermination(error);
      });
    });
  }

  private processStdoutBuffer(): void {
    while (true) {
      const newlineIndex = this.stdoutBuffer.indexOf("\n");
      if (newlineIndex === -1) return;

      const line = this.stdoutBuffer.slice(0, newlineIndex).trim();
      this.stdoutBuffer = this.stdoutBuffer.slice(newlineIndex + 1);

      if (!line) continue;

      let response: MemoryBackendResponse;
      try {
        response = JSON.parse(line) as MemoryBackendResponse;
      } catch (error) {
        this.handleProtocolError(new Error(`Failed to parse memory backend response: ${String(error)}\nline: ${line}`));
        return;
      }

      const pending = this.pending.get(response.id);
      if (!pending) {
        continue;
      }

      this.pending.delete(response.id);
      pending.resolve(response);
    }
  }

  private handleProtocolError(error: Error): void {
    const child = this.child;
    if (child && !child.killed) {
      child.kill();
    }
    this.handleChildTermination(error);
  }

  private handleChildTermination(error: Error): void {
    this.child = undefined;
    this.startPromise = undefined;
    this.stdoutBuffer = "";

    for (const [ id, pending ] of this.pending.entries()) {
      pending.reject(new Error(`Memory backend request ${id} failed: ${error.message}`));
    }
    this.pending.clear();
  }
}

function isSaveResult(value: unknown): value is { inserted: number; skipped: number } {
  return typeof value === "object" && value !== null && "inserted" in value && "skipped" in value;
}

function isMemoryStats(value: unknown): value is MemoryStats {
  return (
    typeof value === "object"
    && value !== null
    && "totalMemories" in value
    && "bySource" in value
    && "databasePath" in value
  );
}
