import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

const VERIFICATION_GUIDELINES = [
  "Never answer factual questions about the current project from memory alone. Read relevant files or run commands first.",
  "When asked about code structure, dependencies, configuration, or behavior, use read, grep, find, or bash to verify before responding.",
  "Prefer checking README files, docs, and explicit configuration over inferring behavior from code.",
  "If you are uncertain about any claim, say so and offer to verify it rather than guessing.",
  "When practical, mention which file or command you used to verify your answer.",
];

const VERIFICATION_RULES_BLOCK = `## Verification Rules
- Do not make factual claims about the current project without checking files, docs, or command output first.
- Prefer read, grep, find, and bash over memory when discussing code, config, repository structure, or dependencies.
- Prefer README files, docs, and explicit configuration over inference.
- If you are unsure, say so and verify instead of guessing.
- When practical, cite the file path or command used for verification.`;

export default function verificationExtension(pi: ExtensionAPI) {
  pi.registerTool({
    name: "verification_rules",
    label: "Verification Rules",
    description: "Internal tool that carries verification-first prompt guidance for the agent.",
    promptSnippet: "Follow verification-first behavior when answering repository and codebase questions.",
    promptGuidelines: VERIFICATION_GUIDELINES,
    parameters: Type.Object({}),
    async execute() {
      return {
        content: [
          {
            type: "text",
            text: "Verification rules are active.",
          },
        ],
        details: {},
      };
    },
  });

  pi.on("before_agent_start", async (event) => {
    return {
      systemPrompt: `${event.systemPrompt}\n\n${VERIFICATION_RULES_BLOCK}`,
    };
  });
}
