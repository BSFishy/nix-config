/**
 * Docs Plugin for OpenCode
 *
 * Replaces the skills system with a simpler docs/ directory convention.
 * Any .md file under docs/ in the project root becomes a loadable document
 * that the agent can pull into context on demand.
 *
 * Optional YAML frontmatter with a `description` field is used to advertise
 * the doc to the agent. Files without a description are still loadable but
 * won't be proactively suggested.
 *
 * Configuration via environment variables:
 *   DOCS_DIR  - directory name to scan (default: "docs")
 */

import fs from "node:fs";
import path from "node:path";

const DOCS_DIR_NAME = process.env.DOCS_DIR || "docs";

// Minimal frontmatter parser — handles the one field we care about
// without pulling in a dependency. Supports `description:` and passes
// everything else through as metadata.
function parseFrontmatter(content) {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/);
  if (!match) return { meta: {}, body: content };

  const meta = {};
  for (const line of match[1].split("\n")) {
    const kv = line.match(/^(\w[\w-]*):\s*(.+)$/);
    if (kv) meta[kv[1].trim()] = kv[2].trim();
  }
  return { meta, body: match[2] };
}

function discoverDocs(docsRoot) {
  const docs = [];
  if (!fs.existsSync(docsRoot)) return docs;

  function walk(dir, prefix) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      if (entry.isDirectory()) {
        walk(path.join(dir, entry.name), prefix ? `${prefix}/${entry.name}` : entry.name);
      } else if (entry.name.endsWith(".md")) {
        const name = entry.name.replace(/\.md$/, "");
        const docName = prefix ? `${prefix}/${name}` : name;
        const filePath = path.join(dir, entry.name);

        let description = "";
        try {
          const raw = fs.readFileSync(filePath, "utf8");
          const { meta } = parseFrontmatter(raw);
          description = meta.description || "";
        } catch {
          // skip unreadable files
        }

        docs.push({ name: docName, filePath, description });
      }
    }
  }

  walk(docsRoot, "");
  return docs;
}

function buildToolDescription(docs) {
  const lines = [
    "Load a document from the project's docs/ directory into context.",
    "",
    "Use this tool when the task at hand matches one of the available documents.",
    "The document content will be injected into the conversation.",
  ];

  const described = docs.filter(d => d.description);
  const undescribed = docs.filter(d => !d.description);

  if (described.length > 0) {
    lines.push("");
    lines.push("## Available docs");
    for (const doc of described) {
      lines.push(`- **${doc.name}**: ${doc.description}`);
    }
  }

  if (undescribed.length > 0) {
    lines.push("");
    lines.push("## Other docs (no description)");
    lines.push(undescribed.map(d => d.name).join(", "));
  }

  if (docs.length === 0) {
    lines.push("");
    lines.push("No docs found in the project's docs/ directory.");
  }

  return lines.join("\n");
}

export const DocsPlugin = async ({ directory, worktree }) => {
  const projectRoot = worktree || directory;
  const docsRoot = path.join(projectRoot, DOCS_DIR_NAME);
  const docs = discoverDocs(docsRoot);

  const docsByName = new Map(docs.map(d => [d.name, d]));

  return {
    tool: {
      docs: {
        description: buildToolDescription(docs),
        args: {
          name: {
            type: "string",
            description: `Name of the document to load. Available: ${docs.map(d => d.name).join(", ") || "(none)"}`,
          },
        },
        async execute(args) {
          const doc = docsByName.get(args.name);
          if (!doc) {
            const available = docs.map(d => d.name).join(", ");
            return `Document "${args.name}" not found. Available docs: ${available || "(none)"}`;
          }

          try {
            const content = fs.readFileSync(doc.filePath, "utf8");
            const { body } = parseFrontmatter(content);
            return `<doc name="${doc.name}">\n${body}\n</doc>`;
          } catch (e) {
            return `Error reading document "${args.name}": ${e.message}`;
          }
        },
      },
    },
  };
};

export default DocsPlugin;
