# Blocked / awaiting-human

Two sections: [PREREQ]s Christopher must supply, and phase-gate checkpoints he must clear.
Editing this file (supplying a PREREQ or clearing a gate) is a Loop-3 trigger: the freed task is pulled immediately.

## [PREREQ]s (PRD v2, five)

| id | what Christopher supplies | blocks | when needed |
|---|---|---|---|
| PREREQ-1 | ~~License confirmation~~ **RESOLVED 2026-07-02: AGPL-3.0, whole repo** (Christopher confirmed) | ~~0.1~~ unblocked | done |
| PREREQ-2 | **Paid Groq tier** (org account + key in backend secret store, never in repo) | 1a.1 **prod cutover only** — dev/free tier unblocks the build | Before Cloud beta traffic |
| PREREQ-3 | **Reformat model ID** (fast Groq LLM per PRD §8) | 1a.2 **final eval sign-off only** — model is env-config (`REFORMAT_MODEL`); build proceeds on a placeholder default | Before eval sign-off / beta |
| PREREQ-4 | **Windows Authenticode cert** (EV or standard; EV skips SmartScreen reputation ramp) | 2.1 | Phase 2 start — lead time on cert issuance is weeks; order during Phase 1 |
| PREREQ-5 | **Price-point confirmation** ($5 Pro / $10 Power / $99 lifetime ×200 per PRD §11) | 2.5 | Phase 2, before Stripe products are created |

## Decisions (not PREREQs in the PRD, surfaced by Run 0 research)

| id | decision | blocks | context |
|---|---|---|---|
| D-1 | ~~Which Dictate to fork~~ **RESOLVED 2026-07-02: v4 (FlorisBoard-based default branch)**, pin `acaf2f07a3d475b6bb63bf614ce4cf9cdcb5370d`; strip list to be drafted at 1c.1 — see harness/research/dictate-internals.md | ~~1c.1~~ unblocked | done |
| D-2 | **DCO vs CLA** — Christopher chose "decide later, BEFORE first outside PR." Guard: repo launches issues-only / PRs closed (or a CONTRIBUTING.md note that PRs are held) until this is decided. One merged PR under ambiguity poisons the relicensing option | first outside PR merge; NOT 0.1 | before contributions open — revisit at Phase 0 exit |

| D-3 | **RESOLVED: repo PRIVATE until launch** (owner deviation from PRD "public day one"). Flip-to-public trigger = start of Phase 2 (F-Droid requires public repo + weeks of review queue — do not slip this) | nothing now; flip-to-public checklist below at Phase 2 | decided 2026-07-02 |

## Flip-to-public checklist (execute at Phase 2 start, per D-3)

- [ ] Make repo public; verify LICENSE/THIRD_PARTY_LICENSES/SECURITY render.
- [ ] Branch protection: require the `gitleaks` status check on main (not enforceable on a free-plan private repo — that's why it waits).
- [ ] Enable private vulnerability reporting (public-repo feature; SECURITY.md already points to it).
- [ ] Re-audit history for secrets before the flip (gitleaks full-history run) — history becomes world-readable retroactively.
- [ ] Then: F-Droid submission (2.2) and launch sequence per PRD §13.

## Awaiting-human verification lanes (Loop 2)

Held until Christopher confirms; never auto-merged:
- 1b.3 physical check: hotkey → live paste into Notepad on a real machine.
- 1c.5 device matrix: Samsung + Pixel physical devices.
- 2.1 signed installer on fresh Windows, no SmartScreen.
- 2.4 unaided first-dictation test with a new user.
- ANY diff touching billing/entitlements or auth flows (1b.4, 1c.4, 2.5, 0.3, 0.5 auth parts): mandatory human review before merge.

## Phase-gate checkpoints (Loop 3 hard stops)

| gate | status |
|---|---|
| Run 0 → Phase 0 (this bootstrap; approve plan + board) | ✅ CLEARED 2026-07-02 by Christopher — Codex Run 1 may take 0.1 |
| Phase 0 → 1 | closed (also revisit D-2 here) |
| Phase 1 → 2 | closed |
| Phase 2 → 3 | closed |
