#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  bash <path-to-plugin>/scripts/claude-review.sh setup
  bash <path-to-plugin>/scripts/claude-review.sh review
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

run_claude_subscription() {
  env \
    -u ANTHROPIC_API_KEY \
    -u ANTHROPIC_AUTH_TOKEN \
    -u CLAUDE_CODE_USE_BEDROCK \
    -u CLAUDE_CODE_USE_VERTEX \
    -u CLAUDE_CODE_USE_FOUNDRY \
    claude "$@"
}

ensure_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "current directory is not inside a git repository"
}

run_setup() {
  require_command git
  require_command claude
  ensure_git_repo

  run_claude_subscription -p "Reply with OK" >/dev/null
  printf 'Setup OK: git repository and Claude Code subscription auth are available.\n'
}

run_review() {
  require_command git
  require_command claude
  ensure_git_repo

  local prompt
  local original_task

  original_task="${CLAUDE_REVIEW_TASK:-Not provided. Infer the implementation intent from the current git diff and repository context.}"

  prompt="$(cat <<EOF
You are Claude Code acting as an independent senior code reviewer.

Review only. Do not modify files.
Do not run tests.
Do not execute commands except read-only commands required for review, such as inspecting the current git diff.
Before inspecting the code changes, first inspect accepted project rules and instructions using read-only tools.
Include AGENTS.md, CLAUDE.md, README or CONTRIBUTING docs, relevant specs, and any nested instructions that apply to changed files when present.
Treat those project rules as review requirements, and mention rule violations or rule-sensitive risks in findings when relevant.
Then review the current git diff only, using Bash for read-only git inspection and Read/Grep/Glob only if extra context is necessary.
Review whether the diff correctly implements the original user task below and take the project constitution rules into account.

Focus on:
- correctness;
- regressions;
- edge cases;
- security issues;
- maintainability;
- missing tests, but do not run tests.

Return a concise code review. Prioritize concrete bugs and acceptance risks first.
Use a numbered list for findings. For each finding, include severity, affected file or line when possible, evidence, impact, and the smallest suggested direction.
Include non-blocking suggestions only after higher-impact findings.
If there are no findings, say exactly: No findings.

Original user task:
$original_task
EOF
)"

  printf '%s' "$prompt" | run_claude_subscription -p --allowedTools Bash,Read,Grep,Glob
}

main() {
  local command_name="${1:-}"

  case "$command_name" in
    setup)
      run_setup
      ;;
    review)
      run_review
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
