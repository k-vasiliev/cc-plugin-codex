# CC Plugin Codex

Codex marketplace repository with one plugin: `cc-plugin-codex`.

The plugin exposes the `claude-review` skill. It runs Claude Code as an
independent, read-only reviewer for the current git diff, shows the review
output to the user, and lets Codex handle actionable findings after inspection.

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

After installing the plugin, ask Codex to use `claude-review` and run the
skill setup check.
