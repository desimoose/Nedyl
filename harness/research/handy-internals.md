# Handy internals (fork target — Windows client)

Run 0 research, 2026-07-02. Repo: https://github.com/cjpais/Handy
**License:** MIT (© 2025 CJ Pais). **Pin commit:** `f13597061ad36b1a4430d61a48aa15a5d4b96e14` (v0.9.0, Tauri 2.10.x).

## Keep (native layer)

**Global hotkey** — dual backend behind `src-tauri/src/shortcut/mod.rs`, selected by `keyboard_implementation` setting: `tauri_impl.rs` (tauri-plugin-global-shortcut) or `handy_keys.rs` (crate `handy-keys` 0.2.4). Press/release lifecycle: `shortcut/handler.rs` → `TranscriptionCoordinator::send_input` (`src-tauri/src/transcription_coordinator.rs`) — PTT vs toggle via `push_to_talk` setting + `Stage` state machine. Actions via `ACTION_MAP` in `src-tauri/src/actions.rs` (`ShortcutAction` trait). Cancel shortcut registered dynamically while recording.

**Audio capture** — cpal 0.16, `src-tauri/src/audio_toolkit/audio/recorder.rs` (`AudioRecorder`): any device format → mono f32 @ 16 kHz (rubato resampler). `stop()` returns `Vec<f32>`. Orchestrated by `AudioRecordingManager` (`src-tauri/src/managers/audio.rs`). Always-on-mic mode, mute-while-recording, feedback sounds, level events for overlay.

**VAD** — Silero VAD v4 ONNX via `vad-rs` (cjpais fork): `audio_toolkit/vad/silero.rs` + `smoothed.rs` (hangover frames). Model resource `resources/models/silero_vad_v4.onnx`. `VadPolicy` gates which frames enter the buffer (silence trimming). Toggleable (`vad_enabled`). Keep as-is.

**Text injection** — `src-tauri/src/clipboard.rs` (`utils::paste`): enigo 0.6 + tauri-plugin-clipboard-manager. `paste_via_clipboard`: save clipboard → write transcript → Ctrl+V (configurable `PasteMethod`) → restore. Caveats: only TEXT clipboard restored (images lost); `paste_delay_ms`; paste must run on main thread; optional auto-submit Enter.

## Strip / replace (the seam)

**Local transcription:** engines transcribe-cpp (whisper.cpp/GGUF) + transcribe-rs (ONNX), wrapped in `enum LoadedEngine` in `src-tauri/src/managers/transcription.rs` (1955 lines). Model download/catalog `src-tauri/src/managers/model.rs` — delete wholesale.

**THE SEAM:** `TranscriptionManager::transcribe(&self, audio: Vec<f32>) -> Result<String>` (transcription.rs:1094) — 16 kHz mono f32 in, text out, called from `TranscribeAction::stop` in `actions.rs` (~line 658). Replace the body (or whole manager) with async HTTP POST (WAV-encode via existing `hound`); stub `initiate_model_load` + streaming methods to no-op. `reqwest` already a dep; `llm_client.rs` is a ready-made OpenAI-compatible HTTP client to crib for Groq BYO mode.

**Settings:** tauri-plugin-store JSON (`src-tauri/src/settings.rs`, `AppSettings` ~line 324, serde-defaulted → backward-compatible new fields). `backend_mode` enum + endpoint/key fields slot straight in; `post_process_api_keys`/`post_process_providers` already model per-provider keys. Types → TS via tauri-specta.

## Friction

- `TranscribeAction::stop` interleaves transcription with capability checks, streaming finalize, overlay states, history (SQLite `managers/history.rs`), OpenCC, LLM post-process — surgical edits, not just the manager swap.
- Streaming-model UI (`OverlayStyle::Live`, `supports_streaming`) + accelerator settings coupled to local engines; React model-picker/accelerator pages to strip.
- tauri-specta bindings regenerate on build — removed commands break TS until regenerated.
- Windows packaging pain (ONNX Runtime, Vulkan DLLs) disappears with local engines. Tray-only background app, single-instance, autostart plugins.
