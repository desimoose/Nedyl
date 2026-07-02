# Nedyl — Build-Ready PRD (Codex Edition, v2 — Open Core)

**Owner:** Christopher
**Date:** July 2026
**Builder:** Codex (implement against this directly)
**Supersedes:** v1 (closed-source, Windows-only). Two changes: Android is back in scope, and the whole product is open source with a paid hosted tier (open-core, à la Supabase/n8n).

---

## Goal

Ship an open-source voice dictation system for **Windows and Android** — hold a hotkey (desktop) or tap the mic key (Android), speak, and clean, punctuated, paste-ready text lands in the focused field — plus a **paid hosted backend (Nedyl Cloud)** that removes all setup: no API keys, one account, synced history, billing.

Free forever if you self-host or bring your own API key. Paid if you want it to just work. The clients are the same either way.

---

## Instructions for the build agent (read first)

1. **Build to the contracts in Sections 6 and 8.** API shapes are fixed. Clients branch on error `code`, never message text.
2. **Fork, do not rebuild.** Desktop = hard fork of `cjpais/Handy` (Windows target). Android = hard fork of `DevEmperor/Dictate`. Keep their native layers (hotkey/injection; IME). Pin fork commits; do not chase upstream.
3. **Do not copy FreeFlow code** (Swift). Port its prompt + Edit Mode design only.
4. **Every client supports three backend modes** (Section 5.0): Nedyl Cloud, self-hosted URL, direct BYO provider key. Mode is a settings choice; the dictation code path is identical.
5. **Nedyl Cloud holds its secrets server-side and meters server-side.** BYO-key mode stores the user's own key locally (their key, their risk, encrypted at rest via OS keystore).
6. **No audio at rest** in the hosted backend. Stream to STT, discard.
7. **Simplicity first.** Universal error shape + one retry. No fallback ladders.
8. **Verification before done.** Every task in Section 14 has a check; complete only when it passes demonstrably.
9. **License headers and notices** per Section 10.5 in every file. This repo is public from day one; commit accordingly (no secrets ever, clean history).
10. **[PREREQ]** items need Christopher; listed in Section 14. They do not block earlier tasks.

---

## 1. Product thesis

**What:** A system-wide AI voice input layer, open source. Windows app (hold hotkey → clean text pasted at cursor) and Android keyboard (mic key → clean text inserted). Cloud STT + LLM cleanup turns speech into finished text, not raw transcription.

**Who:** (a) Windows/Android users ignored by Mac-first tools like Wispr Flow; (b) the self-host/privacy crowd (r/selfhosted, F-Droid users, homelab) who will not run a closed-source keyboard but will run an auditable one; (c) convenience users who pay Nedyl Cloud to skip API-key setup.

**Why it matters:** the good dictation tools are Mac-first and closed. Open source flips the trust problem that kills third-party keyboards (an auditable input layer is trustable; a closed one is spyware until proven otherwise) and unlocks free distribution channels (F-Droid, GitHub, Obtainium) with zero store gatekeeping. The hard native parts are already solved in permissively-licensed OSS. The business is the hosted convenience layer, which is exactly the model proven by Supabase and n8n.

**Positioning:** "Wispr Flow for the rest of us. Open source, Windows + Android first, free if you self-host."

---

## 2. Target user

**Persona A — Windows power typist (buyer).** Types all day. Pain: Windows voice typing is unformatted garbage; good tools are Mac-only. Trigger: dread before a long message; a Mac colleague's Wispr demo. Success moment: first hotkey dictation lands clean in Slack, no edits. Likely pays for Cloud (doesn't want API keys).

**Persona B — Self-hoster / FOSS user (distribution engine).** Pain: refuses closed input software on principle. Workaround: no dictation at all, or clunky local Whisper rigs. Trigger: sees Nedyl on F-Droid / r/selfhosted / GitHub trending. Success: BYO Groq key working in 5 minutes, audits the code, stars the repo, tells others. Mostly won't pay; is the reason Persona A hears about Nedyl. Some convert to Cloud for sync.

**Persona C — Android-only dictator.** Pain: Gboard voice typing produces unpunctuated run-ons. Trigger: F-Droid/Play search for "whisper keyboard." Success: first cleaned message sent from the Nedyl keyboard.

---

## 3. Core workflow

**Windows first run:** nedyl.com or GitHub Releases → download signed installer → launch → choose mode: **Nedyl Cloud** (sign in with Google/magic link, 7-day unlimited trial starts) / **self-hosted** (paste backend URL) / **BYO key** (paste Groq key) → onboarding: mic permission, hotkey shown, guided first dictation → hold hotkey, speak, release → overlay shows listening → transcribing → clean text pastes at cursor.

**Android first run:** F-Droid / GitHub APK (Obtainium-compatible) / Play later → install → system flow to enable the Nedyl keyboard + set input method → same three-mode choice → guided first dictation in a sample field → mic key on the keyboard → speak → clean text inserted.

**Steady state (both):** focus any field → trigger → speak → clean text appears. Each dictation saved to history (local always; synced across devices when on Cloud).

**Upgrade path (Cloud):** trial ends or free daily cap hit → quota response → modal explains + links Stripe checkout → entitlement updates → resumes. **BYO/self-host users are never metered by us** and never see a paywall; they may see a one-time "Cloud does this with zero setup + sync" card, dismissible forever.

---

## 4. MVP scope

### Must-have (v1)
- Windows client (Handy fork): hotkey → backend → clean text pasted. All three backend modes.
- Android client (Dictate fork): IME mic → backend → clean text inserted. All three backend modes.
- Hosted backend (Nedyl Cloud): `/v1/dictate`, auth, metering, Stripe; deployable by anyone via `docker compose up` (self-host parity from day one — same image we run).
- One cleanup mode (dictate).
- Signed Windows installer (nedyl.com + GitHub Releases). Android APK on GitHub Releases (Obtainium-ready) + F-Droid submission.
- In-app update check on both clients (version ping + prompt; F-Droid/Obtainium handle their own updates).
- Public repo(s), license, README with self-host quickstart, CONTRIBUTING.md.

### Should-have (v1.1)
- Synced scratchpad/history (Cloud).
- Tone modes (dictate/note/prompt).
- Custom vocabulary.
- Play Store listing (org account) once F-Droid/GitHub traction exists.

### Later (v2+)
- Edit Mode. macOS/Linux desktop targets (Handy already builds them). On-device/offline STT tier. Additional STT/LLM providers behind the backend. Wake word. Team/org plans.

---

## 5. Features

### 5.0 Backend modes (the open-core mechanism; both clients)
- **Purpose:** one codebase serves free self-hosters and paid Cloud users.
- **Modes:** `cloud` (api.nedyl.com + Nedyl account), `self-hosted` (user's URL + their instance's auth or none), `byo-key` (client calls Groq directly with the user's key; no Nedyl server involved).
- **Acceptance criteria:** mode switch in settings; dictation pipeline identical across modes; BYO key stored in OS keystore (Windows Credential Manager / Android Keystore), never in plaintext config; no Nedyl telemetry in self-host/BYO modes beyond an optional opt-in.
- **Edge cases:** invalid BYO key → clear inline error with a test button; unreachable self-host URL → connection error state, no silent hang; mode switch preserves local history.

### 5.1 Hold-to-dictate and inject (Windows)
As v1: hotkey press-to-record ≤150ms, release → p50 ≤2.0s to pasted clean text; silent recording → "no speech" toast, no paste; client-side duration cap under the 25MB Groq limit; focus-loss pastes wherever focus is on release (documented).

### 5.2 Voice keyboard (Android)
- **User story:** as an Android user I switch to the Nedyl keyboard, tap the mic, speak, and cleaned text is inserted where my cursor is.
- **Acceptance criteria:** IME enable/switch flow guided in onboarding; mic key records, stop → backend → `clean_text` inserted via InputConnection; works in the top messaging/mail apps; inherits Dictate's spoken-command formatting where it maps to our cleanup.
- **Edge cases:** no network → clear inline error, audio retained for one retry; password/secure fields → IME respects `textPassword` etc. and disables dictation there; rotation mid-record survives or cancels cleanly (never crash-loop the IME).

### 5.3 Cleanup / reformat
As v1: filler removed, punctuation/grammar fixed, never invents names, EMPTY on empty; reformat failure falls back to raw transcript flagged `reformatted:false`.

### 5.4 Account, quota, billing (Cloud mode only)
As v1: Supabase auth (Google + magic link); server-side atomic daily metering (UTC); 429 `quota_exceeded` + `upgrade_url` past cap; Stripe Checkout + Customer Portal + webhooks → `entitlements`. BYO/self-host: none of this applies.

### 5.5 History / scratchpad
Local history in all modes (on-device store). Cloud mode adds sync (should-have). RLS owner-only on the hosted DB.

### 5.6 Updates
Both clients ping `/version` (or GitHub Releases API) on launch; prompt with changelog + download link when newer. Never auto-install silently. F-Droid and Obtainium users get updates through those channels natively; the in-app prompt detects install source and defers to it (don't nag F-Droid users to download from GitHub).

### 5.7 Edit Mode (later) — as v1, ported from FreeFlow's design.

---

## 6. Data model (hosted backend; self-host runs the same schema)

Postgres (Supabase hosted; vanilla Postgres in the self-host compose). RLS everywhere.

- **profiles** (user_id PK/FK, plan free|pro|power|lifetime, trial_ends_at, created_at) — owner read; service-role writes.
- **usage_daily** (user_id, date UTC, clips_used; unique(user_id,date)) — atomic increment; owner read.
- **scratchpad** (id, user_id, text, source_device, created_at) — RLS `auth.uid()=user_id` select/insert/delete.
- **entitlements** (user_id, plan, source=stripe, stripe_customer_id, expires_at nullable) — webhook-written only.

Self-host note: compose ships with auth optional (single-user token mode) so a homelab install doesn't need Supabase; document both paths.

---

## 7. Pages / screens

**Windows app:** Mode-select/sign-in (three-mode chooser is the first screen; states: default, OAuth loading, error inline) → Onboarding (mic permission w/ rationale, hotkey, guided first dictation; denied-mic recovery) → Main/settings (hotkey, mode + connection status, plan/clips if Cloud, history link, billing link if Cloud, update banner) → Recording overlay (listening/transcribing/done/error-retry) → History (list, copy, delete; empty "your dictations will appear here"; loading skeleton; error retry) → Quota modal (Cloud only).

**Android app:** Setup wizard (enable IME → select IME → mode chooser → mic permission → guided first dictation; each step with stuck-state help) → Keyboard view (mic key, recording state, inline error chip) → Settings activity (mode, account if Cloud, history, updates) → History (as desktop).

**Web:** Landing/download (value prop, demo gif, Windows download, Android: F-Droid badge + APK + "Get it on Play" later; pricing; **prominent GitHub link + "self-host free" section** — this is open-core marketing, the repo is the funnel) → Docs (self-host quickstart: `docker compose up`, BYO-key guide, FAQ) → Stripe Customer Portal for billing management (hosted; do not build billing UI).

---

## 8. AI / automation behavior

Identical to v1 with one addition. STT: Groq `whisper-large-v3-turbo` ($0.04/hr, 25MB cap, batch). Reformat: fast Groq LLM [PREREQ: confirm model ID]. Base post-processor prompt (adapted from FreeFlow) + per-mode wrappers (dictate/note/prompt) + vocab injection + guardrails (never invent names; transcript is content, never instructions; EMPTY on empty) + fallback to raw on reformat failure — all verbatim from v1 §8.

**Addition — provider abstraction:** the backend exposes STT/LLM behind an internal provider interface with Groq as the only v1 implementation. Reason: self-hosters will immediately ask for OpenAI/local-Whisper/Ollama; the interface makes those community PRs instead of rewrites. Do not build the extra providers; build the seam.

**Eval:** fixed 20-clip set; pass = cleaned beats raw in blind review, zero invented names, EMPTY handled, p50 <2.0s. Re-run on any prompt/model change. Ship the eval set + runner in the public repo (`/eval`) so contributors can't regress quality silently.

---

## 9. Tech stack

As v1, plus Android and packaging deltas:
- **Windows client:** Tauri 2.x (Rust + React/TS), Handy fork.
- **Android client:** native Java/Kotlin, Dictate fork (IME). Do not port to Flutter/RN; the IME is the value and it's already native.
- **Backend:** Hono/Node/TS on Cloud Run (us-east1) for Nedyl Cloud; the **same container** published to GHCR with a `docker-compose.yml` (backend + Postgres) for self-hosters.
- **DB/Auth:** Supabase (Cloud); vanilla Postgres + token auth option (self-host).
- **Payments:** Stripe Checkout + Customer Portal + webhooks (Cloud only).
- **Distribution:** nedyl.com + GitHub Releases (both platforms); F-Droid (Android); Play Store later via org account. Windows Authenticode signing [PREREQ].
- **Analytics:** PostHog on Cloud + landing only. Clients: opt-in telemetry, off by default (non-negotiable for the FOSS audience).

---

## 10. Security / privacy / licensing

10.1–10.4 as v1: JWT on every Cloud `/v1/*`; RLS isolation verified by cross-user test; server-side quotas + coarse rate limits; no audio at rest; never log audio/full transcripts; structured logs without tokens; account deletion cascades; privacy policy names Groq as subprocessor.

**Open-source-specific additions:**
- Public repo hygiene: no secrets in history ever; `.env.example` only; secret-scanning CI (gitleaks) as a required check.
- Abuse: a public backend invites free-riders hitting Nedyl Cloud endpoints from forked clients → Cloud requires auth on everything except `/health` and `/version`; per-IP rate limits on auth endpoints.
- Vulnerability policy: `SECURITY.md` with a private disclosure contact. An input-layer app will get security researcher attention; welcome it.

**10.5 Licensing [PREREQ — Christopher confirms; recommendation below]:**
- **Recommendation: AGPL-3.0 for the entire repo** (backend + both clients). Rationale: MIT (Handy, FreeFlow) and Apache-2.0 (Dictate) code can be incorporated into an AGPL work (one-way compatible), so the fork chain is clean. AGPL keeps the code fully FOSS (F-Droid eligible, community-trustable) while blocking the Supabase-style nightmare: a cloud vendor hosting your backend as a competing paid service without releasing changes. This is the standard open-core defense.
- Alternatives if you disagree: Apache-2.0 everywhere (maximally permissive, Supabase's actual choice, relies on brand+velocity as the moat) or n8n-style sustainable-use (not OSI-approved open source → **kills F-Droid eligibility**; only pick this if F-Droid doesn't matter, and it does for Persona B).
- Obligations regardless: retain Handy/FreeFlow MIT notices and Dictate's Apache NOTICE + changed-file statements; `THIRD_PARTY_LICENSES.md` in the repo.
- Trademark: "Nedyl" name + logo stay Christopher's (trademark policy file); forks must rename for distribution. This is how open-core protects the brand while the code is free.

---

## 11. Monetization

**The line:** the software is free; **convenience and sync are paid.** Self-host/BYO = every core feature, unlimited, forever, zero payment surface. Nedyl Cloud = no keys, no server, one account, synced history, support.

- **Cloud trial:** 7 days unlimited on signup.
- **Cloud Free:** 20 clips/day. Full quality, full injection.
- **Cloud Pro:** $5/mo — unlimited dictation, synced history.
- **Cloud Power:** $10/mo — Pro + custom vocab, priority model, Edit Mode when it ships.
- **Cloud Lifetime:** $99 one-time, 200 founding seats, then retired.
- **Upgrade triggers:** daily cap (primary), trial expiry (secondary), sync/vocab gating (tertiary). BYO/self-host users see at most one dismissible Cloud card, ever.
- **Billing rules:** as v1 (Checkout, Portal, webhooks as source of truth, UTC trial expiry, server-enforced lifetime cap). [PREREQ: confirm price points.]
- **Open-core honesty check:** expect the majority of users to never pay; that's the model. Persona B is the marketing department. Track Cloud conversion against *downloads*, not signups, and expect low single digits.

---

## 12. Success metrics

- **Adoption (new, leading):** GitHub stars trajectory, F-Droid installs, APK/installer downloads, self-host compose pulls (GHCR).
- **Activation:** % of installs completing a first dictation (per platform, per mode). Target 60% Cloud; measure BYO via opt-in telemetry only.
- **Retention:** 4-week retention of activated users (north star).
- **Revenue:** Cloud trial→paid 4–6%; download→paid expect 1–3%; MRR; lifetime seat burn-down.
- **Quality:** eval-set pass rate; STT failure <1%; p50 <2.0s, p95 <4.0s.
- **Community health:** time-to-first-response on issues <48h; merged community PRs; zero unpatched critical vulns >7 days.

---

## 13. Launch plan

- **Beta:** must-haves only, both platforms, Cloud + BYO modes (self-host docs can trail by a week).
- **First users:** 10 hand-onboarded from One Spicy Neuron + network (Cloud path), plus a public "source-available now, v1 soon" repo README to start collecting Persona B watchers early.
- **Launch sequence (order matters):** GitHub repo public + Show HN / r/selfhosted / r/opensource (Persona B ignites distribution) → F-Droid submission (their build/review queue takes weeks; submit early) → Product Hunt with the Cloud pitch → One Spicy Neuron post on the open-core build itself (the meta-story is content).
- **v1 release criteria:** v1's list (8/10 beta users dictate unaided; eval passes; p50 <2.0s; signed installer clean on fresh Windows; one real Stripe conversion; RLS test passes) **plus:** Android APK verified on 3+ physical devices across ≥2 OEMs (Samsung + Pixel minimum — IMEs break per-OEM), self-host compose boots to a working `/v1/dictate` on a clean VM following only the README, and license/notice files audit clean.

---

## 14. Build plan (tasks with verification)

Three tracks after Phase 0: backend, Windows, Android.

### Phase 0 — Foundations
- **0.1** Public monorepo scaffold (`/backend`, `/desktop`, `/android`, `/eval`, `/docs`), LICENSE [PREREQ: confirm AGPL], THIRD_PARTY_LICENSES, SECURITY.md, CI with secret-scanning. *Check:* CI green; gitleaks passes; licenses render on GitHub.
- **0.2** Backend skeleton on Cloud Run + published GHCR image + compose file. *Check:* `curl /health` ok on Cloud Run AND on a local `docker compose up`.
- **0.3** Auth middleware (Cloud: Supabase JWT; self-host: static token mode via env). *Check:* 401 without credentials in both modes.
- **0.4** Stub `/v1/dictate` + `/version`. *Check:* contract shapes returned.
- **0.5** DB schema + RLS (+ tokened single-user variant). *Check:* cross-user read fails under RLS.

### Phase 1a — Backend real
- **1a.1** Provider interface + Groq STT impl. *Check:* 5s WAV → non-empty transcript. [PREREQ: paid Groq tier for prod.]
- **1a.2** Reformat step (Section 8 prompt + modes). *Check:* filler sample cleans; empty → EMPTY. [PREREQ: model ID.]
- **1a.3** Metering + quota (Cloud mode only; self-host unmetered). *Check:* N+1 → 429 with upgrade_url; concurrent calls don't double-spend; self-host mode never 429s.
- **1a.4** `/v1/usage`; upstream-failure handling (one retry → 502 `stt_upstream`). *Checks:* as v1.

### Phase 1b — Windows client
- **1b.1** Fork Handy, pin commit, Windows build runs. *Check:* stock loop works.
- **1b.2** Three-mode settings + keystore-backed key storage. *Check:* BYO key stored in Credential Manager, absent from any config file; invalid key shows test-button error.
- **1b.3** Route dictation per mode (Cloud/self-host → `/v1/dictate`; BYO → Groq direct + local reformat call path). *Check:* hotkey → Notepad paste, cleaned, in all three modes; p50 <2.0s on Cloud.
- **1b.4** Cloud auth + quota modal. *Check:* cap triggers modal → checkout.
- **1b.5** Update check honoring install source. *Check:* higher `/version` prompts.

### Phase 1c — Android client
- **1c.1** Fork Dictate, pin commit, debug build installs, stock IME works. *Check:* mic → text in a chat app.
- **1c.2** Three-mode settings + Android Keystore key storage. *Check:* as 1b.2.
- **1c.3** Route per mode through backend; insert `clean_text`. *Check:* cleaned insertion in all three modes; no direct-Groq traffic in Cloud mode (network log).
- **1c.4** Cloud auth + quota surface in keyboard/settings. *Check:* cap behavior.
- **1c.5** IME hardening: secure fields disabled, rotation-safe, Samsung+Pixel pass. *Check:* device matrix.

### Phase 2 — Distribution
- **2.1** Windows Authenticode in CI. *Check:* fresh-machine install, no SmartScreen. [PREREQ: cert.]
- **2.2** Android release signing + GitHub Releases (Obtainium-compatible metadata) + F-Droid metadata/submission. *Check:* Obtainium tracks and updates from the repo; F-Droid submission accepted into their pipeline.
- **2.3** Landing + docs site (download, self-host quickstart, BYO guide). *Check:* clean-VM compose quickstart succeeds following README only.
- **2.4** Onboarding both platforms. *Check:* new-user unaided first dictation.
- **2.5** Stripe + webhooks + entitlements + Portal. *Check:* test purchase lifts quota. [PREREQ: pricing.]

### Phase 3 — Should-have
- **3.1** Scratchpad sync (Cloud). *Check:* cross-device visibility; RLS holds.
- **3.2** Tone modes. **3.3** Custom vocab. *Checks:* as v1.
- **3.4** Play Store listing (org account) when triggered. *Check:* listing live.

Log check results in `tasks/todo.md`; corrections → `tasks/lessons.md`. (If running under the loop harness, LOOPS-v2 governs; graders map 1:1 to these checks.)

---

## Reference links

**Fork sources:** Handy https://github.com/cjpais/Handy (MIT) · Dictate https://github.com/DevEmperor/Dictate (Apache-2.0) · FreeFlow https://github.com/zachlatta/freeflow (MIT, design donor)
**AI:** Groq STT https://console.groq.com/docs/speech-to-text · models/pricing https://console.groq.com/docs/models
**Platform:** Tauri 2 https://v2.tauri.app · Hono https://hono.dev · Cloud Run https://cloud.google.com/run/docs · Supabase https://supabase.com/docs · Stripe https://stripe.com/docs
**Distribution:** F-Droid inclusion https://f-droid.org/docs/Inclusion_How-To/ · Obtainium https://github.com/ImranR98/Obtainium
**Licensing:** AGPL-3.0 https://www.gnu.org/licenses/agpl-3.0.en.html · Apache/GPL compatibility https://www.apache.org/licenses/GPL-compatibility.html

**[PREREQ]s:** license confirmation (0.1) · paid Groq tier (1a.1 prod) · reformat model ID (1a.2) · Authenticode cert (2.1) · pricing (2.5).
