export interface ChunkOptions {
  maxChars?: number;
  maxBlockChars?: number;
}

const DEFAULT_MAX_CHARS = 3000;
const DEFAULT_MAX_BLOCK_CHARS = 4000;

export function chunkBlocks(blocks: string[], options: ChunkOptions = {}): string[] {
  const maxChars = options.maxChars ?? DEFAULT_MAX_CHARS;
  const maxBlockChars = options.maxBlockChars ?? DEFAULT_MAX_BLOCK_CHARS;

  const normalized = blocks.map((block) => block.trim()).filter(Boolean);
  const chunks: string[] = [];
  let current = "";

  const flush = () => {
    const value = current.trim();
    if (value) chunks.push(value);
    current = "";
  };

  for (const block of normalized) {
    const pieces = splitOversizedBlock(block, maxBlockChars);

    for (const piece of pieces) {
      if (!current) {
        current = piece;
        continue;
      }

      const candidate = `${current}\n\n---\n\n${piece}`;
      if (candidate.length <= maxChars) {
        current = candidate;
      } else {
        flush();
        current = piece;
      }
    }
  }

  flush();
  return chunks;
}

function splitOversizedBlock(block: string, maxBlockChars: number): string[] {
  if (block.length <= maxBlockChars) return [ block ];

  const paragraphs = block
    .split(/\n{2,}/)
    .map((paragraph) => paragraph.trim())
    .filter(Boolean);

  if (paragraphs.length > 1) {
    const chunks: string[] = [];
    let current = "";

    for (const paragraph of paragraphs) {
      if (!current) {
        current = paragraph;
        continue;
      }

      const candidate = `${current}\n\n${paragraph}`;
      if (candidate.length <= maxBlockChars) {
        current = candidate;
      } else {
        chunks.push(current);
        current = paragraph;
      }
    }

    if (current) chunks.push(current);
    return chunks.flatMap((chunk) => splitOversizedBlock(chunk, maxBlockChars));
  }

  const lines = block.split("\n");
  if (lines.length > 1) {
    const chunks: string[] = [];
    let current = "";

    for (const line of lines) {
      if (!current) {
        current = line;
        continue;
      }

      const candidate = `${current}\n${line}`;
      if (candidate.length <= maxBlockChars) {
        current = candidate;
      } else {
        chunks.push(current);
        current = line;
      }
    }

    if (current) chunks.push(current);
    return chunks.flatMap((chunk) => splitOversizedBlock(chunk, maxBlockChars));
  }

  const pieces: string[] = [];
  for (let i = 0; i < block.length; i += maxBlockChars) {
    pieces.push(block.slice(i, i + maxBlockChars));
  }
  return pieces;
}
