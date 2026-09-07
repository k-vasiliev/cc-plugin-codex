#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  [CLAUDE_BIN=/absolute/path/to/claude] bash <path-to-plugin>/scripts/claude-review.sh setup
  [CLAUDE_BIN=/absolute/path/to/claude] [CLAUDE_REVIEW_PATHS=$'path/one\npath/two'] \
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

resolve_claude_bin() {
  if [[ -n "${CLAUDE_BIN:-}" ]]; then
    [[ -x "$CLAUDE_BIN" ]] || die "CLAUDE_BIN is not executable: $CLAUDE_BIN"
    return
  fi

  CLAUDE_BIN="$(command -v claude || true)"
  [[ -n "$CLAUDE_BIN" ]] || die \
    "Claude Code CLI not found in PATH. Install or restore the stable 'claude' command, or set CLAUDE_BIN to an executable absolute path."
}

run_claude_subscription() {
  # Claude settings can re-introduce provider URLs and auth tokens after the
  # process environment is cleared. Review prompts inspect project rules
  # explicitly, so disable user/project/local settings for deterministic
  # first-party subscription authentication.
  env \
    -u ANTHROPIC_API_KEY \
    -u ANTHROPIC_AUTH_TOKEN \
    -u ANTHROPIC_BASE_URL \
    -u CLAUDE_CODE_USE_BEDROCK \
    -u CLAUDE_CODE_USE_VERTEX \
    -u CLAUDE_CODE_USE_FOUNDRY \
    -u CLAUDE_CODE_SIMPLE \
    "$CLAUDE_BIN" --setting-sources "" "$@"
}

ensure_subscription_auth() {
  local auth_output

  if ! auth_output="$(run_claude_subscription auth status 2>&1)"; then
    printf '%s\n' "$auth_output" >&2
    die "Claude Code subscription auth is unavailable. Run 'env -u ANTHROPIC_API_KEY -u ANTHROPIC_AUTH_TOKEN \"$CLAUDE_BIN\" auth login' interactively, then retry. This script does not start login automatically."
  fi
}

ensure_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "current directory is not inside a git repository"
}

run_setup() {
  require_command git
  resolve_claude_bin
  ensure_git_repo
  ensure_subscription_auth

  if ! run_claude_subscription -p "Reply with OK" >/dev/null; then
    die "Claude Code subscription auth could not complete a smoke request. Run 'env -u ANTHROPIC_API_KEY -u ANTHROPIC_AUTH_TOKEN \"$CLAUDE_BIN\" auth login' interactively, then retry. This script does not start login automatically."
  fi
  printf 'Setup OK: git repository and Claude Code subscription auth are available.\n'
}

run_review() {
  require_command git
  resolve_claude_bin
  ensure_git_repo
  ensure_subscription_auth

  local context_instructions
  local prompt
  local original_task
  local review_paths

  original_task="${CLAUDE_REVIEW_TASK:-Not provided. Infer the implementation intent from the current git diff and repository context.}"
  review_paths="${CLAUDE_REVIEW_PATHS:-}"

  if [[ -n "$review_paths" ]]; then
    context_instructions="$(cat <<EOF
The following paths are required review context and must be read and accounted for, even when they are ignored, untracked, or absent from the git diff:
$review_paths

These paths do not restrict the review scope. Inspect any other repository code needed to evaluate the implementation and its contracts.
EOF
)"
  else
    context_instructions="No additional required review context paths were provided."
  fi

  prompt="$(cat <<EOF
You are Claude Code acting as an independent senior code reviewer.

Review only. Do not modify files.
Do not run tests.
Do not execute commands except read-only commands required for review, such as inspecting the current git diff.
Before inspecting the code changes, first inspect accepted project rules and instructions using read-only tools.
Include AGENTS.md, CLAUDE.md, README or CONTRIBUTING docs, relevant specs, and any nested instructions that apply to changed files when present.
Treat those project rules as review requirements, and mention rule violations or rule-sensitive risks in findings when relevant.
Then inspect the current git diff as the primary change set. Use Bash for read-only git inspection and Read/Grep/Glob to inspect any code needed for the review.
$context_instructions
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
