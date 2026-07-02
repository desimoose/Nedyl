#!/usr/bin/env bash
# gate.sh — accumulated regression suite (Loop 2, deterministic).
# Every check from a previously-`done` task is appended here and runs on EVERY attempt.
# A change that breaks the gate fails regardless of its own task check. Nothing merges red.
set -euo pipefail

FAIL=0
check() { # check <name> <cmd...>
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "PASS  $name"; else echo "FAIL  $name"; FAIL=1; fi
}

# ── always-on (from run 0) ─────────────────────────────────────────────
# Public repo: no secrets, ever. Required before any code lands (task 0.1).
check "gitleaks" gitleaks detect --no-banner --redact

# ── appended per done task (template; uncomment/extend as tasks land) ──
# 0.2: check "health-local"   curl -fsS http://localhost:8080/health
# 0.3: check "unauth-401"     test "$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/v1/usage)" = "401"
# 0.4: check "version-shape"  bash harness/graders/task-check.sh 0.4
# 0.5: check "rls-cross-user" bash harness/graders/task-check.sh 0.5
# 1a.3: quota 429 shape · 1b.2/1c.2: no-secrets grep of client build artifacts

exit $FAIL
