/**
 * OpenPeon CESP Sound Pack Plugin for OpenCode
 *
 * Plays sounds from a CESP-compatible sound pack on OpenCode lifecycle events.
 * Cross-platform: macOS (afplay) and Linux (pw-play/paplay/ffplay/mpv/play/aplay).
 *
 * The sound pack path is injected at build time by nix via string replacement.
 *
 * Configuration via environment variables:
 *   OPENPEON_VOLUME    - Master volume 0.0-1.0 (default: 0.5)
 *   OPENPEON_MUTE      - Set to "1" to mute all sounds
 *   OPENPEON_DISABLE   - Comma-separated CESP categories to disable
 *   OPENPEON_DEBOUNCE  - Debounce ms per category (default: 500)
 */

import fs from "node:fs";
import path from "node:path";
import os from "node:os";

// __OPENPEON_PACK_PATH__ is replaced by nix with the store path to the sound pack
const PACK_PATH = "__OPENPEON_PACK_PATH__";

const VOLUME = Math.min(
  1.0,
  Math.max(0.0, parseFloat(process.env.OPENPEON_VOLUME || "0.5")),
);
const MUTED = process.env.OPENPEON_MUTE === "1";
const DISABLED = new Set(
  (process.env.OPENPEON_DISABLE || "").split(",").filter(Boolean),
);
const DEBOUNCE_MS = parseInt(process.env.OPENPEON_DEBOUNCE || "500", 10);

let manifest = null;
const lastPlayed = {}; // category → last picked sound index
const lastFired = {}; // category → epoch ms of last fire
const userMessageTimes = []; // timestamps for spam detection

function loadManifest() {
  try {
    const raw = fs.readFileSync(
      path.join(PACK_PATH, "openpeon.json"),
      "utf8",
    );
    manifest = JSON.parse(raw);
  } catch (e) {
    console.warn("[openpeon] failed to load manifest:", e.message);
  }
}

/**
 * Resolve a CESP category, following aliases if needed.
 * Returns the resolved category name or null if no sounds exist.
 */
function resolveCategory(category) {
  if (manifest?.categories?.[category]?.sounds?.length) return category;
  const alias = manifest?.category_aliases?.[category];
  if (alias && manifest?.categories?.[alias]?.sounds?.length) return alias;
  return null;
}

/**
 * Pick a random sound for a category, excluding the last-played sound
 * to avoid immediate repeats (when more than one sound is available).
 */
function pickSound(category) {
  const resolved = resolveCategory(category);
  if (!resolved) return null;

  const sounds = manifest.categories[resolved].sounds;
  if (sounds.length === 0) return null;
  if (sounds.length === 1) return sounds[0];

  const lastIdx = lastPlayed[resolved];
  const candidates = sounds
    .map((s, i) => ({ sound: s, idx: i }))
    .filter((c) => c.idx !== lastIdx);
  const pick = candidates[Math.floor(Math.random() * candidates.length)];
  lastPlayed[resolved] = pick.idx;
  return pick.sound;
}

/**
 * Fire a sound for a CESP category with debounce and mute checks.
 */
function fireSound(category) {
  if (MUTED || DISABLED.has(category)) return;

  const now = Date.now();
  if (lastFired[category] && now - lastFired[category] < DEBOUNCE_MS) return;
  lastFired[category] = now;

  const sound = pickSound(category);
  if (!sound) return;

  const filePath = path.resolve(PACK_PATH, sound.file);
  if (!fs.existsSync(filePath)) return;

  playAudio(filePath);
}

/**
 * Play an audio file asynchronously without blocking.
 * macOS: afplay
 * Linux: tries pw-play, paplay, ffplay, mpv, play (sox), aplay in order.
 */
function playAudio(filePath) {
  const platform = os.platform();

  try {
    if (platform === "darwin") {
      const proc = Bun.spawn(["afplay", "-v", String(VOLUME), filePath], {
        stdout: "ignore",
        stderr: "ignore",
      });
      proc.unref();
    } else {
      const vol100 = Math.round(VOLUME * 100);
      const vol65536 = Math.round(VOLUME * 65536);
      const cmd = [
        `pw-play --volume=${VOLUME} "${filePath}"`,
        `paplay --volume=${vol65536} "${filePath}"`,
        `ffplay -nodisp -autoexit -volume ${vol100} "${filePath}"`,
        `mpv --no-terminal --volume=${vol100} "${filePath}"`,
        `play -v ${VOLUME} "${filePath}"`,
        `aplay "${filePath}"`,
      ].join(" || ");

      const proc = Bun.spawn(
        ["sh", "-c", `(${cmd}) >/dev/null 2>&1`],
        { stdout: "ignore", stderr: "ignore" },
      );
      proc.unref();
    }
  } catch {
    // silently ignore playback errors — never block the CLI
  }
}

export const OpenPeonPlugin = async () => {
  loadManifest();

  if (!manifest) {
    console.warn("[openpeon] no manifest loaded — plugin disabled");
    return {};
  }

  const subagentSessions = new Set();

  function isSubagent(sessionID) {
    return sessionID && subagentSessions.has(sessionID);
  }

  // Play session.start on plugin init with a small delay
  setTimeout(() => fireSound("session.start"), 100);

  return {
    event: async ({ event }) => {
      switch (event.type) {
        case "session.created": {
          const info = event.properties?.info;
          if (info?.parentID) {
            subagentSessions.add(info.id);
            break;
          }
          fireSound("session.start");
          break;
        }

        case "session.updated": {
          const info = event.properties?.info;
          if (info?.parentID) subagentSessions.add(info.id);
          break;
        }

        case "session.deleted": {
          const info = event.properties?.info;
          if (info?.id) subagentSessions.delete(info.id);
          fireSound("session.end");
          break;
        }

        case "session.status": {
          const sid = event.properties?.sessionID;
          if (isSubagent(sid)) break;
          const status = event.properties?.status;
          const statusType =
            typeof status === "object" ? status?.type : status;
          if (statusType === "busy" || statusType === "running") {
            fireSound("task.acknowledge");
          }
          break;
        }

        case "session.idle": {
          const sid = event.properties?.sessionID;
          if (isSubagent(sid)) break;
          fireSound("task.complete");
          break;
        }

        case "session.error": {
          const sid = event.properties?.sessionID;
          if (isSubagent(sid)) break;
          fireSound("task.error");
          break;
        }

        case "permission.asked": {
          fireSound("input.required");
          break;
        }

        case "message.updated": {
          // Spam detection: if user sends 3+ messages within 5 seconds
          const info = event.properties?.info;
          if (info?.role === "user") {
            const now = Date.now();
            userMessageTimes.push(now);
            while (userMessageTimes.length > 5) userMessageTimes.shift();
            if (userMessageTimes.length >= 3) {
              const window = now - userMessageTimes[0];
              if (window < 5000) {
                fireSound("user.spam");
              }
            }
          }
          break;
        }
      }
    },
  };
};

export default OpenPeonPlugin;
