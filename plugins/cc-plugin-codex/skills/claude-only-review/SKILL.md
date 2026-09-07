---
name: "claude-only-review"
description: "Run Claude Code as an independent reviewer, then report every finding with Codex comments"
compatibility: "Requires a git repository and Claude Code CLI with subscription auth"
metadata:
  author: "k-vasiliev"
---


## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding. Treat it as the original
implementation task that the current diff was supposed to satisfy. Pass only
that implementation task to Claude, not the user's review request text. If
`$ARGUMENTS` is empty, infer the original implementation task from the current
conversation and pass that text instead.

## Workflow

1. From the repository root, run setup before assembling the original task or
   starting the review:

   ```bash
   CLAUDE_BIN="/absolute/path/to/claude" \
     bash "<path-to-this-skill>/../../scripts/claude-review.sh" setup
   ```

   Omit `CLAUDE_BIN` when a stable `claude` command is already available in
   `PATH`. Do not search for or depend on temporary package paths such as
   `.claude-code-*`; restore the stable command or use an explicit executable
   absolute path. If setup reports missing or expired subscription auth, stop
   and ask the user to run the printed `claude auth login` command
   interactively. Never start interactive login automatically.

2. Only after setup succeeds, resolve the original implementation task and any
   files that Claude must read as required review context. Put context paths
   relative to the repository root, one per line, in `CLAUDE_REVIEW_PATHS`.
   These paths are mandatory context, not a scope restriction: Claude may
   inspect any other repository code needed for the review. Use this for
   requested artifacts that may be ignored, untracked, or absent from the
   current git diff.

3. Run Claude review from the repository root:

   ```bash
   CLAUDE_BIN="/absolute/path/to/claude" \
   CLAUDE_REVIEW_PATHS=$'plans/brief.md\nplans/solution.md' \
   CLAUDE_REVIEW_TASK='$ARGUMENTS' \
     bash "<path-to-this-skill>/../../scripts/claude-review.sh" review
   ```

   Replace `<path-to-this-skill>` with the directory containing this `SKILL.md`.
   The review script is bundled with this plugin; do not call a project-local
   `.agents/skills/claude-review` path.

   Omit `CLAUDE_BIN` when `claude` is available in `PATH`. Omit
   `CLAUDE_REVIEW_PATHS` when no explicit context files are required; the
   current git diff remains the primary change set in either case.

   Preserve the original implementation task exactly when setting
   `CLAUDE_REVIEW_TASK`. Do not include review wrapper phrases such as
   "сделай ревью" or constitution instructions in `CLAUDE_REVIEW_TASK`. If
   `$ARGUMENTS` is empty, use the original implementation request from the
   current conversation. If the task contains shell quotes, escape them safely
   before running the command.

4. The bundled review script must make Claude inspect the project's accepted
   rules before reviewing the diff. Claude should consider `AGENTS.md`,
   `CLAUDE.md`, README or CONTRIBUTING docs, relevant specs, and any nested
   instructions that apply to changed files when present.

5. Do not modify files.

6. Read Claude output and inspect only the code context needed to evaluate each
   review point. Use read-only commands.

7. Send the user the review results. For every Claude finding, include a Codex
   comment that states whether you agree, disagree, partially agree, or need
   user clarification, with a concise reason and relevant file references. Do
   not silently drop Claude findings. For each finding, format the problem title
   as bold Markdown text, preserving severity when Claude provides one. Then add
   a short verdict line using `Codex: agree`, `Codex: partially agree`,
   `Codex: disagree`, or `Codex: needs clarification`. Do not stop at that
   verdict: add 3-5 sentences that start by describing the problem in your own
   words, including what behavior or contract is affected, why that can matter,
   and what user or system impact it can have. Then cover the evidence you
   checked, the concrete risk or non-risk, whether the item should be fixed now,
   and the smallest next step when applicable. Write Codex comments in the
   language used in the preceding conversation, unless the user explicitly
   requests another language. If Claude reports no findings, say so.

8. Do not fix anything in this command. If the user asks to fix the findings,
   tell them to run `claude-review-and-fix` or explicitly ask for fixes.

## Runtime

Claude review can legitimately take a long time because it must inspect the
constitution, specs, task description, and git diff before returning findings.
Use a 15 minute timeout before treating the run as stuck.

## Rules

- Do not apply Claude suggestions.
- Do not run tests.
- Claude may use Bash only for read-only review inspection, such as reading the
  current git diff.
- Claude must consider the original implementation task.
- The wrapper forces subscription auth by clearing API-key/cloud-provider
  environment variables for the Claude subprocess.
- Always run setup before review. The wrapper may report the command needed to
  restore subscription auth, but neither the skill nor the wrapper starts an
  interactive login automatically.
- `CLAUDE_REVIEW_PATHS` lists required context files that Claude must read and
  account for. It does not limit which repository code Claude may inspect.
- The wrapper does not assemble diff contents into the prompt.

## Setup

Setup is a required preflight. Use the same `CLAUDE_BIN` value for setup and
review when `claude` is not available in `PATH`:

```bash
CLAUDE_BIN="/absolute/path/to/claude" \
  bash "<path-to-this-skill>/../../scripts/claude-review.sh" setup
```

Setup verifies the Git repository, CLI executable, subscription auth status,
and a minimal subscription request. On an auth failure it prints an interactive
`claude auth login` command and exits without starting login itself.
