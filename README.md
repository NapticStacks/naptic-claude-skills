# naptic-claude-skills

Shared Claude Code skills for the Naptic team.

## Skills

- **`/typeform-create`** — Create branded Typeforms via natural language. Three modes (wizard, spec, sketch) auto-detected from your input. Brand-aware (Omertá, Sunkissed pre-seeded).

## Install

From inside Claude Code:

```
/plugin install NapticStacks/naptic-claude-skills
```

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

- New skills go under `skills/<skill-name>/` with their own `SKILL.md`
- Brand metadata changes (colors, voice notes — NOT theme IDs or tokens) go in `brand-registry/brands.json` via PR
- Open an issue first if you're not sure where something belongs

## Conventions

- Skills follow the gstack/superpowers naming and structure conventions
- All scripts must be `set -euo pipefail` safe
- Tokens, theme IDs, and other account-specific values stay local; only metadata ships in the repo
