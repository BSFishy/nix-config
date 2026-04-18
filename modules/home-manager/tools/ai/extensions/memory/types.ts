export type MemorySource = "compaction" | "session_end" | "manual";

export interface MemoryStats {
  totalMemories: number;
  bySource: Record<string, number>;
  databasePath: string;
}

export interface MemoryChunk {
  content: string;
  createdAt: string;
  metadata?: Record<string, unknown>;
}

export interface SaveMemoryPayload {
  source: MemorySource;
  sessionKey: string;
  sessionFile?: string;
  cwd?: string;
  gitBranch?: string;
  leafId?: string;
  chunks: MemoryChunk[];
  metadata?: Record<string, unknown>;
}

export interface SearchMemoryPayload {
  query: string;
  topK?: number;
  threshold?: number;
  cwd?: string;
}

export interface MemorySearchHit {
  id: number;
  source: string;
  createdAt: string;
  sessionKey: string;
  sessionFile?: string;
  cwd?: string;
  gitBranch?: string;
  leafId?: string;
  content: string;
  metadata?: Record<string, unknown>;
  score: number;
}

export type MemoryBackendRequest =
  | { id: string; type: "health" }
  | { id: string; type: "stats" }
  | { id: string; type: "save"; payload: SaveMemoryPayload }
  | { id: string; type: "search"; payload: SearchMemoryPayload };

export type MemoryBackendSuccessResult =
  | { ok: true }
  | MemoryStats
  | { inserted: number; skipped: number }
  | { hits: MemorySearchHit[] };

export type MemoryBackendResponse =
  | { id: string; ok: true; result: MemoryBackendSuccessResult }
  | { id: string; ok: false; error: string };
