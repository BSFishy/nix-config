function asRecord(value: unknown): Record<string, unknown> | undefined {
  return value !== null && typeof value === "object" ? (value as Record<string, unknown>) : undefined;
}

function readString(value: unknown): string | undefined {
  return typeof value === "string" && value.trim() ? value : undefined;
}

function extractTextFromContent(content: unknown): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";

  return content
    .map((part) => {
      const record = asRecord(part);
      if (!record) return "";

      if (record.type === "text" && typeof record.text === "string") {
        return record.text;
      }

      if (record.type === "image") {
        return "[image omitted]";
      }

      if (record.type === "tool-call") {
        const toolName = readString(record.toolName) ?? "unknown-tool";
        return `[tool call: ${toolName}]`;
      }

      if (record.type === "tool-result") {
        const toolName = readString(record.toolName) ?? "unknown-tool";
        return `[tool result: ${toolName}]`;
      }

      if (typeof record.text === "string") return record.text;
      return "";
    })
    .filter(Boolean)
    .join("\n");
}

function formatMessage(role: string, content: unknown, timestamp?: number | string): string {
  const text = extractTextFromContent(content).trim();
  const header = timestamp ? `${role.toUpperCase()} @ ${String(timestamp)}` : role.toUpperCase();
  return `${header}\n${text || "[no text content]"}`;
}

function formatUnknownEntry(entry: unknown): string {
  try {
    return JSON.stringify(entry, null, 2);
  } catch {
    return String(entry);
  }
}

export function serializeBranchEntries(entries: unknown[]): string[] {
  return entries
    .map((entry) => serializeBranchEntry(entry))
    .filter((entry): entry is string => Boolean(entry && entry.trim()));
}

function serializeBranchEntry(entry: unknown): string | undefined {
  const record = asRecord(entry);
  if (!record) return undefined;

  if (record.type === "message") {
    const message = asRecord(record.message);
    if (!message) return undefined;

    const role = readString(message.role) ?? "unknown";
    const timestamp = typeof message.timestamp === "number" || typeof message.timestamp === "string"
      ? message.timestamp
      : undefined;

    return formatMessage(role, message.content, timestamp);
  }

  if (record.type === "compaction") {
    const summary = readString(record.summary) ?? readString(asRecord(record.compaction)?.summary);
    if (!summary) return undefined;
    return `COMPACTION SUMMARY\n${summary}`;
  }

  if (record.type === "label") {
    return undefined;
  }

  return formatUnknownEntry(entry);
}

export function serializeCompactionMessages(messages: unknown[], previousSummary?: string): string[] {
  const serialized = messages
    .map((message) => serializeMessage(message))
    .filter((entry): entry is string => Boolean(entry && entry.trim()));

  if (previousSummary && previousSummary.trim()) {
    serialized.unshift(`PREVIOUS SUMMARY\n${previousSummary.trim()}`);
  }

  return serialized;
}

function serializeMessage(message: unknown): string | undefined {
  const record = asRecord(message);
  if (!record) return undefined;

  const role = readString(record.role) ?? "unknown";
  const timestamp = typeof record.timestamp === "number" || typeof record.timestamp === "string"
    ? record.timestamp
    : undefined;

  return formatMessage(role, record.content, timestamp);
}
