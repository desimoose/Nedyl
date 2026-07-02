# Nedyl — Loop Stack (LOOPS.md, v2)

**Purpose:** The engineering harness for building Nedyl autonomously, structured as four stacked loops: an agent loop that does the work, a verification loop that grades it and feeds failures back, an event-driven loop that triggers runs without a human invoking them, and a hill-climbing loop that analyzes run traces and rewrites the harness itself. The spec is `nedyl-prd-codex-v1.md`; it defines WHAT. This file defines the machine that builds it.

**Design rule:** each loop wraps the one inside it. Build them in order; each is useful before the next exists. Loop 1+2 first (a graded builder), Loop 3 second (hands-off operation), Loop 4 last (compounding improvement).

```
┌─ Loop 4: Hill-climb ── analyzes traces, rewrites the harness ─┐
│ ┌─ Loop 3: Events ──── triggers runs on commits/cron/unblock ─┐│
│ │ ┌─ Loop 2: Verify ── grades output, feeds failures back ──┐ ││
│ │ │ ┌─ Loop 1: Agent ─ Codex: task → tools → attempt done ┐ │ ││
│ │ │ └──────────────────────────────────────────────────────┘ │ ││
│ │ └──────────────────────────────────────────────────────────┘ ││
│ └──────────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────────┘
```

---

## Shared state (all loops read/write these)

```
/nedyl-prd-codex-v1.md    # spec (read-only for loops 1-3; loop 4 may PROPOSE changes, never apply)
/LOOPS.md                 # this file (read-only for loops 1-3; loop 4 proposes patches via PR)
/harness/agent-prompt.md  # the Codex system/task prompt — loop 4's primary optimization target
/harness/graders/         # rubrics + scripts the verification loop runs
/tasks/todo.md            # task board from PRD §14: id | status | grader ref | evidence
/tasks/blocked.md         # tasks gated on [PREREQ]s or human verify
/traces/                  # one JSONL per run: task, plan, diffs, grader results, retries, outcome
/tasks/journal.md         # human-readable digest per run (generated from the trace)
```

Every run appends a trace. Traces are the raw material loop 4 mines. Without them there is no hill to climb — treat trace-writing as non-optional plumbing from run one.

---

## Loop 1 — The agent loop (Codex does one task)

**Shape:** pull ONE task from `tasks/todo.md` → plan → edit code with tools → attempt completion → emit result + trace. That's it. Loop 1 does not decide whether the work is good; that's loop 2's job.

**Rules for the inner agent (encode in `harness/agent-prompt.md`):**
1. One task per run. First `todo` task in phase order (PRD §14) whose deps are `done` and which isn't in `blocked.md`.
2. Build to the PRD contracts exactly. Never invent API shapes, fields, or alternative formats.
3. Minimal diff. No drive-by refactors. No side quests.
4. Secrets server-side; metering server-side; no audio at rest (PRD instructions 4, 5, 8).
5. If the task needs a [PREREQ], move it to `blocked.md` with exactly what's needed and take the next task.
6. If no task is selectable, emit a STATUS trace and exit cleanly.
7. Write the trace: task id, plan, files touched, commands run, self-assessment.

**Non-goal:** self-verification beyond compile/run sanity. The agent claims "attempt complete"; the grader decides.

---

## Loop 2 — The verification loop (grade, feed back, retry)

**Shape:** agent's attempt → graders run → PASS: merge, mark done, next / FAIL: structured feedback re-enters the agent's context → retry, max R attempts → still failing: park + flag.

**Graders (in `/harness/graders/`), two kinds:**

*Deterministic (scripts). Fast, cheap, run on every attempt:*
- `gate.sh` — the accumulated regression suite: every check from previously `done` tasks (PRD §14 checks: /health ok, 401 unauth, quota 429 shape, RLS cross-user denial, no-secrets grep of client build, etc.). A change that breaks the gate fails regardless of its own task check.
- `task-check.sh <id>` — the specific §14 assertion for the current task.
- `diff-scope.sh` — the diff touches only files plausibly in-scope for the task (flag, don't hard-fail, on new deps or config edits).

*Agentic (LLM-as-judge). Run where scripts can't judge quality:*
- `reformat-judge` — runs the fixed 20-clip eval set (PRD §8.3) through `/v1/reformat`; grades against the rubric: filler removed, punctuation added, no invented names, EMPTY handled, mode wrapper honored. Blind-compares clean vs raw. This is the product's core quality bar, so it runs on any change touching the reformat path, prompt, or model.
- `contract-judge` — diffs API responses against the PRD shapes when endpoint code changes.

**Feedback mechanics:** a failing grade returns to the agent as structured input: `{task, attempt_n, grader, expected, observed, hint}`. The retry prompt includes the failure verbatim, not a summary. Max **R = 3** attempts per task per run; after that the task is parked `failing` in todo.md with the full grader output attached, and the run ends. (This replaces "two strikes then journal" with an explicit budget the harness enforces rather than the agent self-polices.)

**Human-as-grader (sensitive lanes):** some checks cannot or must not be auto-graded. These are `awaiting-human` in blocked.md, and the merge is held until Christopher confirms:
- Hotkey → live paste into Notepad on a real machine (physical check).
- Signed installer on a fresh Windows box, no SmartScreen (task 2.1).
- Any change touching billing/entitlements or auth flows — human review before merge, always.

**Merge rule:** PASS on task-check + green gate + (if triggered) judge pass + (if sensitive) human sign-off → commit `feat: task X.Y [graded:pass]`, mark done with evidence. Nothing merges red.

---

## Loop 3 — The event-driven loop (nobody invokes it)

**Shape:** events fire → a run of loops 1+2 executes → results land in the repo and traces. The builder becomes a background system, not a command you type.

**Triggers (wire via GitHub Actions or the agent platform's cron/webhooks):**

| Event | Reaction |
|---|---|
| Cron (e.g. hourly during build sprints) | Standard run: next task through loops 1+2 |
| Push to main / merged task | Immediate next-task run (keeps momentum between crons) |
| CI red on main | **Repair run:** the failure is the task; fix-forward or revert. Preempts all other work |
| `blocked.md` edited (a [PREREQ] supplied or human-verify confirmed) | Unblock run: pull the freed task immediately |
| PRD change merged by Christopher | Re-plan run: regenerate affected todo.md entries before any build run |
| Grader-parked task sits `failing` > 24h | Escalation: STATUS report to Christopher (Slack/email webhook), no retry spam |

**Safety valves:**
- Concurrency 1. One run at a time; events queue. Parallel agents on one repo is how you get merge hell.
- Kill switch: a `/HALT` file in repo root; every run checks it first and exits if present.
- Phase boundaries still hard-stop for Christopher's review (PRD §14 phases 0→1→2→3). The event loop resumes only when he clears the checkpoint in blocked.md.
- Budget cap per day (runs or spend); exceeded → STATUS and sleep.

---

## Loop 4 — The hill-climbing loop (the harness improves itself)

**Shape:** periodically (cron: daily, or every N runs), an **analysis agent** — a separate run, never the builder mid-task — reads the accumulated `/traces/` and answers: where does the builder repeatedly stumble, and what harness change would prevent it? Then it applies the fix to the harness, not to the product code.

**What it mines from traces:**
- Tasks needing 2-3 attempts and WHY (which grader, which failure class).
- Repeated failure patterns across tasks (e.g. "agent keeps inventing response fields" → contract examples belong in the agent prompt; "reformat-judge keeps failing on names" → the reformat system prompt needs a stronger constraint — which is a PRODUCT prompt fix, flagged separately).
- Grader misfires: checks that pass work a human then rejects, or block work that was fine. Graders are config too.
- Wasted motion: re-exploring the same files every run → add a repo map to the agent prompt; retry loops on flaky externals → adjust retry/backoff in the harness.

**What it may change, by autonomy level:**
- **Auto-apply (commit directly):** `harness/agent-prompt.md` wording, grader hints/rubric clarifications, todo.md task splitting, adding examples to prompts. Tag commits `harness:` so they're auditable and revertible.
- **Propose via PR (Christopher approves):** changes to LOOPS.md itself, retry budget R, event triggers/cadence, the reformat product prompt (PRD Appendix territory), any grader's pass/fail threshold.
- **Never:** the PRD's contracts/scope, billing logic, security rules. It may file an issue saying the spec looks wrong; it may not route around it.

**The compounding effect (why this loop exists):** each cycle makes loops 1-2 fail less and converge faster, which makes loop 3's unattended runs safer. This is the automated version of `lessons.md` — instead of the builder journaling lessons and hopefully re-reading them, the analysis agent bakes lessons directly into the prompt and graders the builder runs with next time. Keep a short `harness/CHANGELOG.md` so Christopher can audit what the hill-climber changed and roll back anything that made things worse (climb-downs happen; the gate protects you).

---

## Human oversight map (where Christopher sits in each loop)

| Loop | Human touchpoint |
|---|---|
| 1 Agent | Supplies [PREREQ]s (Groq tier, model ID, signing cert, pricing) via blocked.md |
| 2 Verify | Acts as grader for physical checks, and mandatory reviewer for billing/auth diffs |
| 3 Events | Phase-boundary checkpoints; /HALT kill switch; escalation pings on parked tasks |
| 4 Hill-climb | Approves PR-level harness changes; audits harness/CHANGELOG.md; can revert any harness: commit |

---

## Bootstrap order

1. **Run 0 (manual):** create the file tree above; populate todo.md from PRD §14 with each task's check as its grader ref; seed blocked.md with the four [PREREQ]s; write `harness/agent-prompt.md` v1 (the Loop-1 rules + PRD pointer); stub `gate.sh`.
2. **Runs 1-N (manual invoke):** loops 1+2 only. Watch 3-5 runs by hand, tune the agent prompt and graders on what you see. Do not automate a builder you haven't watched work.
3. **Enable Loop 3:** wire cron + push + blocked-edit triggers, concurrency 1, /HALT, phase stops. Let it run Phase 0-1 semi-attended.
4. **Enable Loop 4:** once ~15-20 traces exist (before that there's no signal), schedule the analysis agent daily with auto-apply limited to prompt/grader hints, everything else via PR.

**Done =** PRD §13 v1 release criteria all green in a final STATUS, every §14 task through Phase 2 `done` with grader evidence, all human-verify items confirmed. Loop 3+4 then continue as the maintenance machine post-launch — the same stack that built it keeps improving it.
