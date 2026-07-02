# Per-run kickoff prompt for Codex (paste verbatim each run)

Read these files in order before doing anything:
1. `AGENTS.md` — craft rules; every diff must comply.
2. `harness/agent-prompt.md` — your role, task-selection rules, build rules, trace format.
3. `source/nedyl-prd-codex-v2.md` — the spec. §6 and §8 contracts are fixed; never invent shapes.
4. `tasks/todo.md` and `tasks/blocked.md` — the board and what's gated.
5. `harness/research/` — fork internals (Handy seam, Dictate v4 map, FreeFlow prompts). Use these instead of re-exploring the fork sources.
6. `tasks/lessons.md` — corrections from prior runs.

Then execute exactly ONE Loop-1 run per `harness/agent-prompt.md`:
- Select the first selectable task (phase order, deps done, not blocked, gate open).
- State your plan (3–6 bullets) before writing code.
- Build the minimal diff. Run the task's §14 check once yourself if cheap.
- Append your trace line to `traces/run-<n>.jsonl` (next n).
- Set the task's status in `tasks/todo.md` to `in-progress` at start; leave it `in-progress` with a "attempt complete — awaiting grade" note in the evidence column when you finish. You never mark `done` — graders do.
- STOP. One task, one run. Do not start another task, do not refactor beyond scope, do not touch harness files except todo.md status and your trace.

If the selected task needs something only Christopher can supply, move it to `tasks/blocked.md` with exactly what's needed and take the next selectable task. If nothing is selectable, write a STATUS trace and stop.
