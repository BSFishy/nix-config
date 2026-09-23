---
name: dependency-validation
description: >
  Validate specific behavior in a dependency by inspecting its actual source and
  writing/running focused tests. Use when a dependency's behavior, edge case,
  integration, or compatibility needs evidence rather than assumptions.
---

# Dependency Validation

## Goal

Establish whether a specific dependency behavior works as expected by tracing
its implementation and exercising the relevant path in tests. Report what the
evidence proves, including limits; do not treat source inspection or a passing
unrelated test suite as proof of the requested behavior.

## Workflow

1. **Clarify the claim**
   - Identify the exact input, configuration, versions, environment, expected
     result, and failure conditions under question.
   - Ask for missing details that materially change the result. Separate the
     user's expected behavior from what the dependency documents or implements.

2. **Find authoritative source**
   - Load and follow the `fetch-project` skill to find or obtain the dependency
     repository. Follow its rules for local checkouts, asking before clone, and
     selecting a version/ref.
   - Record the repository path and tested ref/version. Inspect the implementation,
     relevant docs, existing tests, fixtures, and test instructions to trace the
     exact code path before designing a test.
   - The purpose is to validate behavior from inside the dependency: add focused
     tests to that dependency's source tree using its native test framework. This
     allows tests to exercise private/internal APIs, invariants, and implementation
     paths that are not available through its public interface.
   - Keep the test change isolated from production code. Check the checkout's
     status first, preserve pre-existing user changes, and avoid overwriting or
     reverting them. Report every file changed and offer to remove only test files
     created for this validation when finished.
   - If the dependency checkout is read-only, shared, or not safe to modify, ask
     before making a disposable copy/worktree or choosing another test location.

3. **Choose a safe validation strategy**
   - Select the narrowest test that directly distinguishes the expected behavior:
     unit tests for isolated logic, integration tests for component boundaries,
     or an end-to-end test when the claim depends on the full system.
   - Reuse the project's declared test runner and conventions. Keep tests
     repeatable, bounded, and explicit about setup and cleanup.
   - Prefer mocks, local fixtures, and ephemeral containers/services. Never use
     production services, credentials, or data for validation.

4. **Get consent before provisioning**
   - Before starting, installing, or provisioning any service, container,
     database, cloud resource, paid API, or other persistent/external resource,
     explain what is needed, where it will run, expected cost/network/data impact,
     and cleanup plan; wait for explicit user approval.
   - This applies even if the service is described in repository instructions.
     Do not expose secrets or send user data to an external service.
   - Local in-process tests that need no new service can proceed normally. If
     approval is declined, offer a no-service alternative or stop.

5. **Implement and execute**
   - Write the focused test(s) in the dependency checkout, documenting only
     non-obvious assumptions. Prefer package-private/internal test access patterns
     already used by that project; avoid widening the public API just to test it.
   - Run the target test first, then relevant adjacent tests if practical. Capture
     commands, versions, and complete failure context. Do not claim validation if
     the test did not run or did not cover the requested case.
   - If the behavior fails, distinguish a dependency defect from a harness,
     environment, version, or incorrect expectation. Do not silently alter the
     expected result to make the test pass.

6. **Clean up and report**
   - Stop and remove only resources created for the test, following the agreed
     cleanup plan. Preserve user-owned data and pre-existing services.
   - Summarize the traced code path, test location and command, tested version,
     observed result, and any limitations. Clearly state whether the claim was
     validated, falsified, or remains inconclusive.

## Safety and evidence rules

- Do not install packages globally or change shared machine configuration without
  explicit approval; prefer project-local or ephemeral environments.
- Do not run migrations, destructive commands, or tests against non-disposable
  data. Confirm the target and reset procedure before using a disposable database.
- Treat a passing test as evidence only for its asserted inputs, environment, and
  dependency version. Mention untested dimensions such as platforms or versions.
- Keep validation changes isolated and report exactly which files were created or
  modified.
