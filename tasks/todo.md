# Nedyl task board

Source of truth for WHAT: `source/nedyl-prd-codex-v2.md` §14. Harness rules: `source/LOOPS-v2.md`.
One row per task: `id | status | grader ref | evidence`.

**Status values:** `todo` · `blocked` (see tasks/blocked.md) · `in-progress` · `failing` (parked after R=3, grader output attached) · `awaiting-human` · `done`.
**Grader ref** = the PRD §14 check, enforced by `harness/graders/task-check.sh <id>` (deterministic) plus judges where noted. Every `done` task's check joins `gate.sh` permanently.
**Phase gates:** a phase's tasks are selectable only after Christopher clears the previous phase's checkpoint in `tasks/blocked.md`.

## Phase 0 — Foundations

| id | status | grader ref | evidence |
|---|---|---|---|
| 0.1 | awaiting-human | CI green; gitleaks passes as required check; LICENSE + THIRD_PARTY_LICENSES + SECURITY.md render on GitHub | Attempt 2 graded PASS locally 2026-07-02 (commit `0c55c13`: clean tree, files.zip ignored + absent from commit, 37 files all in-scope). Remaining = GitHub-side: create public repo, push, require gitleaks check, enable private vuln reporting, verify CI green + renders → then done |
| 0.2 | todo | `curl /health` returns ok on Cloud Run AND on local `docker compose up` | — |
| 0.3 | todo | 401 without credentials in both auth modes (Supabase JWT; self-host static token) | — |
| 0.4 | todo | `/v1/dictate` + `/version` stubs return PRD §6/§8 contract shapes (contract-judge on change) | — |
| 0.5 | todo | cross-user read fails under RLS; tokened single-user variant works | — |

## Phase 1a — Backend real

| id | status | grader ref | evidence |
|---|---|---|---|
| 1a.1 | todo | 5s WAV → non-empty transcript via provider interface (Groq impl) — ⚠ PREREQ-2 gates prod tier only, dev proceeds on free tier | — |
| 1a.2 | todo | filler sample cleans; empty audio → EMPTY; reformat-judge passes 20-clip eval — ⚠ PREREQ-3 model ID is env-config; final eval sign-off waits on it | — |
| 1a.3 | todo | N+1 clip → 429 `quota_exceeded` + `upgrade_url`; concurrent calls don't double-spend; self-host mode never 429s | — |
| 1a.4 | todo | `/v1/usage` shape correct; upstream failure → one retry → 502 `stt_upstream` | — |

## Phase 1b — Windows client (Handy fork)

| id | status | grader ref | evidence |
|---|---|---|---|
| 1b.1 | todo | forked at pinned commit; Windows build runs; stock loop works | — |
| 1b.2 | todo | BYO key in Windows Credential Manager, absent from all config files (no-secrets grep); invalid key → inline error with test button | — |
| 1b.3 | todo | hotkey → Notepad paste, cleaned, in all three modes; p50 <2.0s on Cloud — physical paste check is awaiting-human | — |
| 1b.4 | todo | daily cap triggers quota modal → Stripe checkout link — billing-adjacent: human review before merge | — |
| 1b.5 | todo | higher `/version` prompts with changelog; install source honored | — |

## Phase 1c — Android client (Dictate fork)

| id | status | grader ref | evidence |
|---|---|---|---|
| 1c.1 | todo | forked at pinned commit; debug build installs; stock IME mic → text in a chat app | — |
| 1c.2 | todo | BYO key in Android Keystore, absent from config/prefs plaintext; invalid key → test-button error | — |
| 1c.3 | todo | cleaned insertion in all three modes; network log shows zero direct-Groq traffic in Cloud mode | — |
| 1c.4 | todo | cap behavior surfaces in keyboard + settings — billing-adjacent: human review before merge | — |
| 1c.5 | todo | secure fields disabled; rotation-safe; Samsung + Pixel device matrix passes — awaiting-human (physical devices) | — |

## Phase 2 — Distribution

| id | status | grader ref | evidence |
|---|---|---|---|
| 2.1 | todo | fresh-machine install, no SmartScreen — ⚠ PREREQ-4 cert; awaiting-human (physical check) | — |
| 2.2 | todo | Obtainium tracks + updates from repo; F-Droid submission accepted into pipeline | — |
| 2.3 | todo | clean-VM `docker compose up` quickstart succeeds following README only | — |
| 2.4 | todo | new-user unaided first dictation, both platforms — awaiting-human | — |
| 2.5 | todo | test purchase lifts quota via webhook → entitlements — ⚠ PREREQ-5 pricing; billing: human review always | — |

## Phase 3 — Should-have

| id | status | grader ref | evidence |
|---|---|---|---|
| 3.1 | todo | cross-device scratchpad visibility; RLS holds (cross-user test) | — |
| 3.2 | todo | tone modes pass per-mode reformat-judge rubric | — |
| 3.3 | todo | custom vocab injected into prompt; eval names preserved | — |
| 3.4 | todo | Play Store listing live (triggered post-traction) | — |
