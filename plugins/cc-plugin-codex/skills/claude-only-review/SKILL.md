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

1. Run Claude review from the repository root:

   ```bash
   CLAUDE_REVIEW_TASK='$ARGUMENTS' bash "<path-to-this-skill>/../../scripts/claude-review.sh" review
   ```

   Replace `<path-to-this-skill>` with the directory containing this `SKILL.md`.
   The review script is bundled with this plugin; do not call a project-local
   `.agents/skills/claude-review` path.

   Preserve the original implementation task exactly when setting
   `CLAUDE_REVIEW_TASK`. Do not include review wrapper phrases such as
   "сделай ревью" or constitution instructions in `CLAUDE_REVIEW_TASK`. If
   `$ARGUMENTS` is empty, use the original implementation request from the
   current conversation. If the task contains shell quotes, escape them safely
   before running the command.

2. Do not modify files.

3. Read Claude output and inspect only the code context needed to evaluate each
   review point. Use read-only commands.

4. Send the user the review results. For every Claude finding, include a Codex
   comment that states whether you agree, disagree, partially agree, or need
   user clarification, with a concise reason and relevant file references. Do
   not silently drop Claude findings. If Claude reports no findings, say so.

5. Do not fix anything in this command. If the user asks to fix the findings,
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
- The wrapper does not assemble diff contents into the prompt.

## Setup

To verify local prerequisites:

```bash
bash "<path-to-this-skill>/../../scripts/claude-review.sh" setup
```
