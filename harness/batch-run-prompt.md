# Batch run prompt for Codex (multi-task; graded afterward as a batch)

Read first, in order: `AGENTS.md` · `harness/agent-prompt.md` · `source/nedyl-prd-codex-v2.md` (+ v1 where v2 says "as v1") · `tasks/todo.md` · `tasks/blocked.md` · `harness/research/` · `tasks/lessons.md`.

Then loop: execute Loop-1 runs back-to-back WITHOUT waiting for grades between tasks, under these rules.

## Per task
1. Select the first selectable task (phase order; deps done; not blocked; gate open).
2. Plan (3–6 bullets) before code. Minimal diff, PRD contracts exactly.
3. Self-check: run every locally-runnable part of the task's §14 check once (PowerShell equivalents are fine where the grader script needs bash — record what you ran). If the check fails, fix and re-check; **two consecutive self-check failures on the same task → mark it `failing` in todo.md with the observed output, and move to the next selectable task.**
4. Commit on completion: `feat: task <id> [attempt-1] awaiting-grade` — one commit per task, tree clean between tasks. Never push.
5. Trace line per task appended to `traces/run-<n>.jsonl` (increment n per task). Update the task's todo.md row to `in-progress` + "attempt complete — awaiting grade" evidence.

## Cloud-side residuals (expected in Phase 0)
Tasks 0.2/0.3/0.5 have parts needing Christopher's accounts (Cloud Run deploy, Supabase project). Build the code + env-driven config + docker-compose path, verify the LOCAL half (compose `/health`, static-token 401, single-user schema), and record the cloud half in the evidence column as `awaiting-human: <exact step>`. Do not create cloud resources; do not stub around them silently. If Docker isn't available locally, note it in evidence and verify what you can (unit-level checks, `node` direct run).

## Hard stops — end the batch and report
- Phase boundary reached (all Phase 0 tasks attempted → STOP; Phase 1 gate is closed).
- A task would require inventing a contract shape, a secret, or a [PREREQ] value.
- Two tasks in a row parked `failing`.
- Anything would touch files outside the task's scope beyond trivial config.

## Batch report (final output)
Table: task id · attempt result · self-checks run + outcomes · residuals for humans · commit hash. The verifier (Claude) grades the whole batch afterward; nothing you commit is pushed until graded.

Reminder: secrets never; no audio at rest; metering server-side; error `code` branching; provider seam = interface + Groq only; SPDX headers per file; you never mark `done`.
