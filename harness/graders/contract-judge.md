# contract-judge — agentic grader (STUB, Run 0)

**Triggers:** any diff changing endpoint handlers, response serialization, or error paths.
**Job:** diff actual API responses against the PRD contract shapes. Contracts come from `source/nedyl-prd-codex-v2.md` §6 (data model) and §8 (behavior) — plus v1 §6/§8 where v2 says "as v1". Shapes are FIXED; the judge never accepts "equivalent" alternatives.

**Checks:**
1. Response fields: exact names, types, nullability. No extra undocumented fields on `/v1/*`.
2. Error shape universal: every error carries a machine `code` (e.g. `quota_exceeded`, `stt_upstream`); clients must be able to branch on `code` alone.
3. Status codes: 401 unauth, 429 quota (+ `upgrade_url`), 502 upstream after exactly one retry.
4. `reformatted:false` fallback flag present on raw-fallback responses.
5. Self-host mode: identical shapes, no Cloud-only fields leaking (no `upgrade_url` where unmetered).

**Output shape:** `{endpoint, field_or_code, expected, observed, hint}` — feeds Loop-2 retry verbatim.
