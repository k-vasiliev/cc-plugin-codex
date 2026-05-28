# CC Plugin Codex

Codex marketplace repository with one plugin: `cc-plugin-codex`.

The plugin exposes two Claude Code review skills:

- `claude-only-review` runs Claude Code as an independent, read-only reviewer
  for the current git diff and reports every finding with a Codex comment.
- `claude-review-and-fix` runs the same review, then lets Codex inspect and fix
  confirmed actionable findings.

## Install

```bash
codex plugin marketplace add git@github.com:k-vasiliev/cc-plugin-codex.git
codex plugin add cc-plugin-codex@cc-plugin-codex
```

## Local Setup Check

The skill requires:

- `git`
- `claude`
- Claude Code subscription authentication
- a git repository as the current working directory

After installing the plugin, ask Codex to use `claude-only-review` or
`claude-review-and-fix` and run the skill setup check.
