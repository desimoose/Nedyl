#!/usr/bin/env bash
# diff-scope.sh <id> — soft grader: does the diff touch only files plausibly in-scope for the task?
# FLAGS (exit 3), never hard-fails, on: new dependencies, CI/config edits, files outside the task's track.
# STUB (Run 0): scope map to be filled as the monorepo layout exists (task 0.1).
set -euo pipefail

ID="${1:?usage: diff-scope.sh <task-id>}"
# Track roots: 0.* → repo root/.github · 1a.* → /backend · 1b.* → /desktop · 1c.* → /android · 2.* → mixed · 3.* → per-feature
echo "TODO: compare git diff --name-only against scope map for $ID; flag new deps (package/lock/Cargo/gradle changes)"
exit 2
