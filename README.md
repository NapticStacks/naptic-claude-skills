# naptic-claude-skills

Shared Claude Code skills for the Naptic team.

## Skills

- **`/typeform-create`** — Create branded Typeforms via natural language. Three modes (wizard, spec, sketch) auto-detected from your input. Brand-aware (Omertá, Sunkissed pre-seeded).

## Install

This repo is a Claude Code **plugin marketplace**. Install in two steps from inside Claude Code:

```
/plugin marketplace add NapticStacks/naptic-claude-skills
/plugin install typeform-create@naptic-skills
```

The first command registers the marketplace (one-time per machine). The second installs the `typeform-create` plugin from it. Repeat the second command for any future plugins added to this repo.

## Per-skill setup

### `/typeform-create`

Each brand you'll use needs a Typeform personal access token stored locally:

```bash
mkdir -p ~/.config/typeform
# For Omertá (token from Alex's Typeform account — ask Darien for it)
echo "tfp_xxx..." > ~/.config/typeform/omerta.token
chmod 600 ~/.config/typeform/omerta.token

# For Sunkissed (when applicable)
echo "tfp_yyy..." > ~/.config/typeform/sunkissed.token
chmod 600 ~/.config/typeform/sunkissed.token
```

Tokens live only on your machine, never in this repo.

## Contributing

- New plugins go under `plugins/<plugin-name>/` with their own `.claude-plugin/plugin.json` and `skills/<skill-name>/SKILL.md`
- Register each new plugin in `.claude-plugin/marketplace.json` so `/plugin install` can find it
- Brand metadata changes for `typeform-create` (colors, voice notes — NOT theme IDs or tokens) go in `plugins/typeform-create/brand-registry/brands.json` via PR
- Open an issue first if you're not sure where something belongs

## Conventions

- Skills follow the gstack/superpowers naming and structure conventions
- All scripts must be `set -euo pipefail` safe
- Tokens, theme IDs, and other account-specific values stay local; only metadata ships in the repo
