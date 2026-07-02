# reformat-judge — agentic grader (STUB, Run 0)

**Triggers:** any diff touching the reformat path, the post-processor prompt, or the model config.
**Input:** the fixed 20-clip eval set (`/eval` in the monorepo, ships public per PRD §8) run through `/v1/dictate`'s reformat stage.

**Rubric (all must hold):**
1. Filler removed (um/uh/like, false starts).
2. Punctuation + grammar corrected.
3. ZERO invented names or content — any hallucinated proper noun is an automatic FAIL.
4. Empty/non-speech input → literal `EMPTY`.
5. Mode wrapper honored (dictate/note/prompt, once tone modes exist).
6. Blind pairwise: cleaned beats raw transcript for ≥ threshold of clips (threshold change = Loop-4 PR, not auto-apply).
7. Reformat failure falls back to raw flagged `reformatted:false` (never blocks output).

**Latency gate alongside:** p50 <2.0s, p95 <4.0s on the eval run.
**Output shape:** `{clip_id, pass|fail, criterion_failed, expected, observed, hint}` per clip — feeds Loop-2 retry verbatim.
