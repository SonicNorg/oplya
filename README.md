# oplya — Claude Code Plugin Marketplace

Personal plugin marketplace — multi-agent dev workflows. `oplya` is a public, Git-based Claude Code marketplace that hosts personal plugins for sharing with the team. The first plugin, `zapili`, packages a rigorous multi-agent development workflow driven from a `TASK.md` in your working directory.

## Plugins

| Plugin | Description |
|--------|-------------|
| [`zapili`](plugins/zapili/README.md) | Multi-agent dev workflow: research → plan → wave-parallel implementation with codex review |

## Install

```bash
/plugin marketplace add SonicNorg/oplya
/plugin install zapili@oplya
```

`zapili` requires the `codex` CLI to be installed and authenticated — see the [plugin README](plugins/zapili/README.md) for full prerequisites.

## Local development

```bash
git clone https://github.com/SonicNorg/oplya
cd oplya
./scripts/install-hooks.sh        # one-time: enables manifest validation on commit
./scripts/validate-manifests.sh   # run anytime to check manifests
```

If you have the `claude` CLI installed, you can also run a deeper supplementary check:

```bash
claude plugin validate . --strict
```

## Status

Current release: **v1.1.0** (2026-05-29). See [CHANGELOG.md](CHANGELOG.md) for the full delivery list and [.planning/REQUIREMENTS.md § "Acceptance Criteria"](.planning/REQUIREMENTS.md) for the verifiable acceptance set. Every requirement (49 of 49: 43 v1 + 6 v1.1) is implemented and stamped in `.planning/REQUIREMENTS.md` § "Traceability".

## License

MIT — see [LICENSE](LICENSE).
