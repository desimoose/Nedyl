#!/usr/bin/env bash
# task-check.sh <id> — runs the specific PRD §14 check for one task.
# STUB (Run 0): cases are implemented as their tasks are attempted, BEFORE the attempt is graded.
# The check text lives in tasks/todo.md (grader ref column); this script makes it executable.
set -euo pipefail

ID="${1:?usage: task-check.sh <task-id>}"

case "$ID" in
  0.1) echo "TODO: CI green + gitleaks required-check + license files render"; exit 2 ;;
  0.2) echo "TODO: curl /health ok on Cloud Run AND local compose"; exit 2 ;;
  0.3) echo "TODO: 401 unauth in both auth modes"; exit 2 ;;
  0.4) echo "TODO: /v1/dictate + /version contract shapes (then contract-judge)"; exit 2 ;;
  0.5) echo "TODO: RLS cross-user denial + single-user token variant"; exit 2 ;;
  1a.*|1b.*|1c.*|2.*|3.*) echo "TODO: implement check for $ID from tasks/todo.md grader ref"; exit 2 ;;
  *) echo "unknown task id: $ID"; exit 1 ;;
esac
