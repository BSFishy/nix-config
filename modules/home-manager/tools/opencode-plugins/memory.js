import fs from "fs";
import path from "path";

const SAVE_INTERVAL = Number.parseInt(
  process.env.MEMORY_SAVE_INTERVAL || "5",
  10,
);

const HOME = process.env.HOME || ".";
const STATE_DIR = process.env.MEMORY_HOOK_STATE_DIR
  || path.join(HOME, ".opencode", "memory_hook_state");
const STATE_FILE = path.join(STATE_DIR, "opencode.json");
const TOOL_PREFIX = process.env.MEMORY_TOOL_PREFIX || "qmd_";

const AUTO_SAVE_REASON =
  "AUTO-SAVE checkpoint. Save key topics, decisions, quotes, and code from this session to your memory system. Organize into appropriate categories. Use verbatim quotes where possible. Continue conversation after saving.";

const COMPACTION_REASON =
  "COMPACTION IMMINENT. Save ALL topics, decisions, quotes, code, and important context from this session to your memory system. Be thorough — after compaction, detailed context will be lost. Organize into appropriate categories. Use verbatim quotes where possible. Save everything, then allow compaction to proceed.";

const SESSION_IDLE_REASON =
  "SESSION IDLE. Save any unsaved topics, decisions, quotes, and code from this session to your memory system. Organize into appropriate categories. Use verbatim quotes where possible.";

const state = {
  sessions: {},
};

const seenUserMessages = new Map();

function ensureStateDir() {
  fs.mkdirSync(STATE_DIR, { recursive: true });
}

function loadState() {
  try {
    const raw = fs.readFileSync(STATE_FILE, "utf8");
    const parsed = JSON.parse(raw);
    if (parsed && typeof parsed === "object") {
      state.sessions = parsed.sessions || {};
    }
  } catch {
    state.sessions = {};
  }
}

function saveState() {
  ensureStateDir();
  fs.writeFileSync(STATE_FILE, JSON.stringify({ sessions: state.sessions }, null, 2));
}

function getSession(sessionID) {
  if (!state.sessions[sessionID]) {
    state.sessions[sessionID] = {
      userCount: 0,
      lastSaveCount: 0,
      pendingSave: false,
      pendingInjected: false,
      pendingReason: "",
    };
  }
  return state.sessions[sessionID];
}

function getSeenSet(sessionID) {
  if (!seenUserMessages.has(sessionID)) {
    seenUserMessages.set(sessionID, new Set());
  }
  return seenUserMessages.get(sessionID);
}

function markSavePending(sessionID, reason) {
  const session = getSession(sessionID);
  session.pendingSave = true;
  session.pendingInjected = false;
  session.pendingReason = reason;
  saveState();
}

function markSaveComplete(sessionID) {
  const session = getSession(sessionID);
  session.lastSaveCount = session.userCount;
  session.pendingSave = false;
  session.pendingInjected = false;
  session.pendingReason = "";
  saveState();
}

function maybeScheduleSave(sessionID) {
  const session = getSession(sessionID);
  const sinceLast = session.userCount - session.lastSaveCount;
  if (sinceLast >= SAVE_INTERVAL && session.userCount > 0) {
    markSavePending(sessionID, AUTO_SAVE_REASON);
  }
}

function instructionFor(reason) {
  return `## QMD Notebook Checkpoint\n${reason}\n\nDecide if the conversation so far is noteworthy for long-term context. If yes, write or update notes in the QMD notebook using tools with prefix ${TOOL_PREFIX} (for example: qmd_write_note, qmd_append_note). If nothing is noteworthy, respond with a short confirmation that no note was needed.`;
}

export const MemoryHooks = async ({ client }) => {
  loadState();

  return {
    event: async ({ event }) => {
      if (event.type === "message.updated") {
        const info = event.properties?.info;
        if (info?.role === "user") {
          const sessionID = info.sessionID;
          const seen = getSeenSet(sessionID);
          if (!seen.has(info.id)) {
            seen.add(info.id);
            const session = getSession(sessionID);
            session.userCount += 1;
            saveState();
            maybeScheduleSave(sessionID);
          }
        }
      }

      if (event.type === "session.idle") {
        const sessionID = event.properties?.sessionID;
        if (sessionID) {
          const session = getSession(sessionID);
          if (session.userCount > session.lastSaveCount && !session.pendingSave) {
            markSavePending(sessionID, SESSION_IDLE_REASON);
          }
        }
      }
    },

    "tool.execute.after": async (input) => {
      if (input.tool?.startsWith(TOOL_PREFIX)) {
        markSaveComplete(input.sessionID);
      }
    },

    "experimental.session.compacting": async (input, output) => {
      markSavePending(input.sessionID, COMPACTION_REASON);
      output.context.push(instructionFor(COMPACTION_REASON));
    },

    "experimental.chat.system.transform": async (input, output) => {
      const session = getSession(input.sessionID || "unknown");
      if (session.pendingSave && !session.pendingInjected) {
        output.system.push(instructionFor(session.pendingReason || AUTO_SAVE_REASON));
        session.pendingInjected = true;
        saveState();
      }
    },
  };
};
