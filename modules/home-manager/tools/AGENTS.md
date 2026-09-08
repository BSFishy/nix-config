## Verification Rules

- Do not make factual claims about the current project without checking files, docs, or command output first.
- Prefer read, grep, find, and bash over memory when discussing code, config, repository structure, or dependencies.
- Prefer README files, docs, and explicit configuration over inference.
- If you are unsure, say so and verify instead of guessing.
- When practical, cite the file path or command used for verification.
- Use the project's declared task runner for operations that depend on project-loaded
  credentials, environment, or lifecycle conventions. Inspect its recipes before
  replacing it with an ad-hoc command or direct provider API call.

## Stateful Data Safety

- Before modifying or recovering irreplaceable stateful data, stop or freeze writers, preserve byte-for-byte copies of the current state, and operate from copies whenever possible.
- When backup or restore correctness matters, verify both transport integrity and application-level structure instead of relying only on command success.
