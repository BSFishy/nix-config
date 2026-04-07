import fs from "fs";
import path from "path";
import { tool } from "@opencode-ai/plugin";

const HOME = process.env.HOME || ".";
const DEFAULT_ROOT = path.join(HOME, "notebook");
const NOTEBOOK_ROOT = process.env.QMD_NOTEBOOK_ROOT
  || process.env.NOTEBOOK_ROOT
  || DEFAULT_ROOT;

function ensureNotebookPath(relativePath) {
  if (!relativePath || typeof relativePath !== "string") {
    throw new Error("path is required");
  }

  if (path.isAbsolute(relativePath)) {
    throw new Error("path must be relative to the notebook root");
  }

  const withExt = path.extname(relativePath) ? relativePath : `${relativePath}.md`;
  const root = path.resolve(NOTEBOOK_ROOT);
  const fullPath = path.resolve(root, withExt);

  if (fullPath !== root && !fullPath.startsWith(`${root}${path.sep}`)) {
    throw new Error("path escapes the notebook root");
  }

  return { root, fullPath, relative: withExt };
}

function normalizeContent(content) {
  if (typeof content !== "string") {
    throw new Error("content must be a string");
  }

  return content.endsWith("\n") ? content : `${content}\n`;
}

export const qmd_write_note = tool({
  description: "Create a markdown note under the notebook root",
  args: {
    path: tool.schema.string().describe("Relative path like project/subsystem/topic"),
    title: tool.schema.string().optional().describe("Optional H1 title"),
    content: tool.schema.string().describe("Markdown content"),
    overwrite: tool.schema.boolean().optional().describe("Overwrite if file exists"),
  },
  async execute(args) {
    const { fullPath, relative } = ensureNotebookPath(args.path);
    fs.mkdirSync(path.dirname(fullPath), { recursive: true });

    const body = normalizeContent(args.content);
    const header = args.title
      ? (body.trimStart().startsWith("#") ? "" : `# ${args.title}\n\n`)
      : "";
    const output = `${header}${body}`;

    const flag = args.overwrite ? "w" : "wx";
    fs.writeFileSync(fullPath, output, { flag });

    return `wrote ${relative}`;
  },
});

export const qmd_append_note = tool({
  description: "Append markdown content to a note under the notebook root",
  args: {
    path: tool.schema.string().describe("Relative path like project/subsystem/topic"),
    content: tool.schema.string().describe("Markdown content to append"),
    separator: tool.schema.string().optional().describe("Separator before content"),
  },
  async execute(args) {
    const { fullPath, relative } = ensureNotebookPath(args.path);
    fs.mkdirSync(path.dirname(fullPath), { recursive: true });

    const separator = args.separator ?? "\n\n";
    const body = normalizeContent(args.content);
    fs.appendFileSync(fullPath, `${separator}${body}`);

    return `appended ${relative}`;
  },
});

export const qmd_index_update = tool({
  description: "Refresh the QMD index (optionally run embeddings)",
  args: {
    embed: tool.schema.boolean().optional().describe("Run embeddings after update"),
  },
  async execute(args) {
    const update = await Bun.$`qmd update`.text();
    if (args.embed) {
      const embed = await Bun.$`qmd embed`.text();
      return `${update.trim()}\n${embed.trim()}`.trim();
    }

    return update.trim();
  },
});
