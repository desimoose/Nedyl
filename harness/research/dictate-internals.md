# Dictate internals (fork target — Android client)

Run 0 research, 2026-07-02. Repo: https://github.com/DevEmperor/Dictate
**License:** Apache-2.0 (FlorisBoard heritage; NOTICE file present — retain + changed-file statements).
**Default-branch pin candidate:** `acaf2f07a3d475b6bb63bf614ce4cf9cdcb5370d` (2026-07-02).

## ⚠ CRITICAL FINDING — fork-choice decision needed before 1c.1

The default branch is NOT the lightweight Java app the PRD assumed. **Dictate v4 is a complete rebuild as a FlorisBoard fork**: Kotlin + Compose, ~292 source files, package `dev.patrickgold.florisboard.*`, full keyboard (layouts, themes, clipboard, extensions), Wear OS module, accessibility overlay, sherpa-onnx local STT. The old Java IME (v1–v3) is frozen on branch **`legacy-java`** — far smaller, but unmaintained.

Trade: v4 = modern toolchain + a real typeable keyboard (Persona C needs to TYPE too) + provider seam already interface-shaped, but a big surface to strip/maintain. legacy-java = minimal, matches "mic key + insert" scope, but frozen and Java. Decision logged in tasks/blocked.md (D-1); does not block Phase 0.

## Findings (current default branch, v4)

**IME lifecycle** — `app/src/main/kotlin/dev/patrickgold/florisboard/FlorisImeService.kt` extends `LifecycleInputMethodService`; `onCreateInputView()` mounts Compose `ImeRootView` onto `android.R.id.content` (FlorisBoard pattern). `onStartInputView` wraps `EditorInfo` → `FlorisEditorInfo`; handles instant-recording, pending file transcription, interrupted-recording resume. Password fields: `InputAttributes.Variation.PASSWORD/VISIBLE_PASSWORD/WEB_PASSWORD` in `ime/editor/EditorInstance.kt` (→ our 1c.5 secure-field check builds on this). Recording state: process-wide singleton `DictateController` (`dictate/DictateController.kt`, 1577 lines), `MutableStateFlow<UiState>` (Idle/Recording/Transcribing/Rewording/Error/Interrupted) — rotation-safe; interrupted recordings persisted to cache and offered for resend (→ our "audio retained for one retry" edge case is already built).

**Audio** — `dictate/audio/RecordingController.kt`: AudioRecord streaming PCM → 16 kHz mono PCM16 WAV (~1.9 MB/min), app cache. No hard duration cap; oversize surfaces as API error (`CONTENT_SIZE_LIMIT`). Bluetooth-SCO routing, pause/resume.

**Provider calls — THE SEAM** — all HTTP in `lib/dictate-core/.../provider/OpenAiCompatibleClient.kt` (module `:lib:dictate-core`), OkHttp 4.12 + kotlinx.serialization. `transcribe()` (multipart, OpenAI/Groq/Mistral/custom + vendor variants), `complete()` (chat/completions), `listModels()`. Base URL fully configurable via `ProviderRegistry.kt` — a Groq preset already exists (`https://api.groq.com/openai/v1/`), plus arbitrary custom endpoints. Local sherpa-onnx path sits behind the same `TranscriptionProvider` interface (`Providers.kt`) — **our three backend modes slot behind `TranscriptionProvider`/`LlmProvider` as new implementations**, no plumbing invention needed.

**⚠ Keys are plaintext today** — `ProviderAccount` keyring serialized as JSON in JetPref datastore (`AppPrefs.kt` `providerAccounts`), NOT encrypted. Our 1c.2 (Android Keystore) is a real fix, not a checkbox.

**Rewording (→ tone modes)** — `lib/dictate-core/.../provider/DictateRewording.kt` (`apply()`: optional auto-formatting → ordered auto-apply prompts, best-effort each). Prompts in `DictatePromptDefaults.kt` (`REWORDING_BE_PRECISE`, `buildAutoFormattingPrompt`, per-language punctuation) + user prompts in SQLite `prompts.db` + downloadable Prompt Library. UI: Smartbar prompt chips (`ui/DictatePromptStrip.kt`) with `applyPrompt` (selection), `startLivePrompt` (spoken instruction), queued `pendingPrompts` during recording. Maps directly to dictate/note/prompt mode chips; `startLivePrompt` ≈ future Edit Mode entry point.

**Text insertion** — `dictate/DictationSink.kt`: `EditorSink.commitText` → `editorInstance.commitText` (InputConnection), select-all-then-replace support, simulated typing speed. Alternate `overlay/AccessibilitySink.kt` for floating-bubble mode. Spoken punctuation via LLM prompts, not regex.

**Settings** — single Compose activity (`app/FlorisAppActivity.kt`) + `app/Routes.kt`. Dictate screens under `app/settings/dictate/` (Providers, Rewording, Prompts, Proxy, Languages, Wear, Stats). Backend-mode chooser = new route replacing `DictateProvidersScreen`/`ProviderRegistry` presets.

**Toolchain** — minSdk 26, target/compileSdk 36, Kotlin 2.3.20, AGP 9.2.1, Compose BOM 2026.03. Fresh, not stale. Friction is breadth: keyboard layouts/themes/extensions, Wear module, overlay service, native sherpa-onnx, benchmark module — strip list needed at 1c.1.
