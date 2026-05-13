# `/typeform-create` Skill — Design

**Status:** approved 2026-05-13 (brainstorm session)
**Distribution:** Claude Code plugin shipped from `NapticStacks/naptic-claude-skills` (new team repo)
**Audience:** Darien, Jordan, Ben — and anyone else on the Naptic team who needs to create branded Typeforms
**Owner:** Darien (initial author; Jordan to review plugin-repo conventions before first install)
**Origin:** Built after creating Omertá Global Experiences Typeform via API (form `JLAdaLeu`); codifying that flow as a reusable, team-shared skill so future Typeform creation is fast across brands and skill levels.

---

## Goal

A Claude Code slash command (`/typeform-create`) that creates production-ready Typeforms via the Typeform Create API, meeting the user wherever they are on the spectrum from "I've never made a Typeform" to "here's a complete spec, build it."

The skill is brand-aware (Omertá and Sunkissed pre-seeded, new brands learned on demand) and produces fully themed forms — colors, fonts, logo — with one invocation.

It ships as a team plugin so Darien, Jordan, and Ben all get the same skill and the same updates with `/plugin update`.

## Non-goals (v1)

- Editing or updating existing Typeforms (read-only past-form reference is in scope; mutation is not)
- Reading/reporting form responses (separate future skill: `/typeform-responses`)
- Listing forms (separate future skill: `/typeform-list`)
- Sharing tokens across team members (each user configures their own local tokens for the brands they have access to; tokens never live in the plugin repo)
- Slack-bot integration (separate project, brainstormed in its own session)

## Architecture

### Three modes, auto-detected

The skill reads the user's invocation and routes to one of three internal flows. The user does not pick the mode — Claude infers it from how much spec was provided.

| Mode | Trigger heuristic | Flow |
|---|---|---|
| **Wizard** | Sparse input — "make me a typeform", "I want a form for X" with no fields named | Skill asks structured questions one at a time (form title → fields → required-ness → branding) and builds when done |
| **Spec** | Full structured paste — multiple pages or sections, named fields, multiple-choice options visible | Skill detects the structure, asks at most one clarifying question for any genuine ambiguity, builds verbatim |
| **Sketch** | Goal + audience, no field structure — "intake for buyer leads", "qualify Omertá applicants" | Skill drafts a proposed page-by-page breakdown, shows it as a preview, takes feedback, iterates, builds when user approves |

All three modes converge on the same final step: POST to `/forms`, return the public URL and edit URL, log the design choices to inventor notebook.

### Distribution: Claude Code plugin

The skill ships as a plugin from `NapticStacks/naptic-claude-skills` (new GitHub repo, Naptic org).

**Repo layout:**

```
naptic-claude-skills/
├── README.md                    # what this is, how to install, contribution norms
├── .claude-plugin/
│   └── plugin.json              # plugin manifest (name, version, skills list)
├── skills/
│   └── typeform-create/
│       ├── SKILL.md             # main skill file
│       ├── brand-resolver.md
│       ├── api-reference.md
│       ├── modes/
│       │   ├── wizard.md
│       │   ├── spec.md
│       │   └── sketch.md
│       ├── helpers/
│       │   └── build-form.sh
│       └── DESIGN.md            # this file (moved into the repo on first commit)
└── brand-registry/
    └── brands.json              # team-shared brand metadata (theme_ids, workspace_ids, voice notes — NOT secrets)
```

**Install path for team members:**

```
/plugin install NapticStacks/naptic-claude-skills
```

After install, `/typeform-create` is available everywhere. Updates ship via `/plugin update`.

**What ships in the repo vs. what stays local:**

| Ships in plugin | Stays on each user's machine |
|---|---|
| Skill files (SKILL.md, mode prompts, helpers) | API tokens (per-brand, see below) |
| Brand registry (`brands.json` with theme_ids, workspace_ids, colors, voice notes) | Inventor notebook log |
| Documentation | Cache of which themes have been verified on this machine |

**Jordan review:** before first install across the team, Jordan does a 5-minute pass on the plugin repo to make sure structure matches gstack/superpowers conventions he's already using. This is captured as a checkpoint in the implementation plan.

### Per-brand token model

Because multiple team members install the same skill but each has their own Typeform account access, tokens are **per-brand and per-user-machine**.

Token file structure on each user's machine:

```
~/.config/typeform/
├── omerta.token       # token for the Omertá Typeform account (currently Alex's)
└── sunkissed.token    # token for the Sunkissed Typeform account (if separate)
```

**Resolution:** when the skill resolves a brand, it looks up `~/.config/typeform/<brand>.token`. If missing, the skill stops with a clear setup message:

> *"No `omerta.token` found at `~/.config/typeform/`. To set it up: 1) ask Darien or Alex for the Omertá Typeform personal access token, 2) save it to `~/.config/typeform/omerta.token` with `chmod 600`. Then re-run."*

**Backward-compat:** the existing token at `~/.config/typeform/token` (the one Alex pasted today) will be renamed to `omerta.token` as part of the implementation plan's first step.

**Token sharing across the team is out of scope.** Whoever owns the brand account is responsible for distributing the personal access token to the team members who need it (1Password, Slack DM, etc.). The plugin documents this clearly.

### Brand registry

Lives in the plugin repo at `brand-registry/brands.json`. Ships pre-seeded with Omertá; Sunkissed metadata included but with `theme_id: null` so the first Sunkissed invocation on any machine triggers theme creation against that machine's Sunkissed account and writes the resulting theme_id back to a **local cache** (not the repo — different accounts could produce different theme_ids).

```jsonc
{
  "default": "omerta",
  "brands": {
    "omerta": {
      "display_name": "Omertá",
      "theme_id": "M9lt1iSI",
      "workspace_id": "cahxDC",
      "workspace_name": "omerta travel",
      "logo_path": "~/Pictures/Omerta-Brand/omerta-logo.jpg",
      "colors": { "bg": "#1A1A1A", "text": "#F5F5F5", "accent": "#D4D4D4" },
      "font": "Libre Baskerville",
      "voice_notes": "Sophisticated, monochrome luxury. Em dashes OK on public-facing forms. No emojis. Anonymous tone."
    },
    "sunkissed": {
      "display_name": "Sunkissed",
      "theme_id": null,
      "workspace_id": null,
      "logo_path": "<discovered from naptic-content-engine/brands/sunkissed/ during first-use bootstrap>",
      "colors": { "comment": "discovered during first-use bootstrap from existing brand config in omerta-cortex or naptic-content-engine" },
      "font": "<from brand config>",
      "voice_notes": "<from brand config>"
    }
  }
}
```

**Brand resolution order:**
1. Explicit flag (`/typeform-create --brand sunkissed ...`)
2. Detected from user input (the strings "Omertá", "Sunkissed", or other registered brand names)
3. Asks user if ambiguous and more than one brand is plausible
4. Falls back to `default` (omerta)

**First-time bootstrap for any brand with `theme_id: null` in the shipped registry:**
1. Read brand source files (location varies — for Sunkissed: `naptic-content-engine/brands/sunkissed/` or equivalent in `omerta-cortex` if found there). Plugin docs name a small list of canonical lookup paths; if none exist locally, the skill asks the user.
2. Populate `colors`, `font`, `voice_notes`, `logo_path` from discovered config (and confirm with the user before proceeding so the team registry matches)
3. Call `POST /themes` with those values; store returned theme_id in the **local cache** at `~/.config/typeform/local-themes.json`
4. Optionally PR the resolved brand colors/voice notes (NOT the theme_id, which is account-specific) back to the plugin repo so the next team member benefits
5. Proceed with form creation

**Theme verification on every run:** before using a theme_id, the skill does a quick `GET /themes/{id}` to confirm it still exists in the user's account. If not (theme deleted, different account), it re-bootstraps. Cheap insurance against drift.

**Unknown brand path:** if the user invokes for a brand not in the registry (e.g., "for NextHome"), the skill asks: any hex colors, logo path, workspace name? Saves a new entry to the local cache and prompts the user to PR it to the plugin repo if it's a brand the team should know about.

### Past-form reference

When in **wizard** or **sketch** mode and the user seems uncertain about structure or voice, the skill calls `GET /forms?workspace_id=<resolved>` to surface existing forms in the same brand's workspace, then offers them as style references:

> *"In the Omertá account I see 'Omertá Global Experiences' (9-question intake, dark theme) and 'Sunkissed House Apt...' (66 responses). Want me to model voice/length/structure off either, or start fresh?"*

If the user picks a model, skill calls `GET /forms/{id}` to pull that form's fields. The fields are used as **style and structural reference only** — they inform the wizard's question flow and the sketch's draft, but the new form is built fresh, not cloned.

**Skipped in spec mode** — full structured paste means the user knows what they want; no need to surface prior forms.

### Branding application

Every created form has the resolved brand's theme attached via `theme.href` in the form payload. Same pattern that worked today.

**Logo upload** (the piece skipped in the manual flow):

1. Read `logo_path` from the brand registry
2. POST the image to `https://api.typeform.com/images` and capture the returned image ID
3. Attach the image to the form's welcome screen as `layout.attachment` so the brand mark renders above the welcome title

**Graceful degradation:** if the `/images` call fails (untested endpoint — possible quirks around file size, format, or auth), the skill does NOT bail. It logs the failure, finishes building the form without the logo attachment, and tells the user: *"Logo upload failed (reason: …). Form is live without the logo — drop the image manually at <edit URL>."* This is no worse than today's manual step.

### Inventor notebook logging

Per Darien's global CLAUDE.md: every design choice gets logged. Because the plugin is multi-user, each user logs to their own machine — the plugin does not centralize notebooks.

**Log path:** `~/.config/typeform/inventor-log.md` (per-machine, not in the plugin repo)

Each entry contains: timestamp, invoking user (from `git config user.name` or `whoami` as fallback), mode used (wizard/spec/sketch), brand, form title, form ID, the user's original prompt (verbatim), and any non-trivial design choices the skill made (e.g., "made Instagram field optional, all others required" or "added age 18+ gate").

Users who want centralized notebook archival (e.g., Darien aggregating to darien-cortex, or Jordan to engineer-pipeline) can hook the log path with their own cron/copy job. The skill itself stays local.

## File layout

**In the plugin repo (`NapticStacks/naptic-claude-skills`):**

```
naptic-claude-skills/
├── README.md
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── typeform-create/
│       ├── SKILL.md              # Claude's instructions
│       ├── DESIGN.md             # this document
│       ├── brand-resolver.md     # brand detection + resolution logic
│       ├── api-reference.md      # Typeform API patterns
│       ├── modes/
│       │   ├── wizard.md
│       │   ├── spec.md
│       │   └── sketch.md
│       └── helpers/
│           └── build-form.sh     # thin POST /forms wrapper
└── brand-registry/
    └── brands.json               # team-shared brand metadata
```

**On each user's machine (created on first run if missing):**

```
~/.config/typeform/
├── omerta.token                  # personal access token for Omertá Typeform account (per-user)
├── sunkissed.token               # personal access token for Sunkissed account (when team gets one)
├── local-themes.json             # per-machine cache of theme IDs (account-specific)
└── inventor-log.md               # this user's design-choice log
```

## Slash command

**Name:** `/typeform-create`

Long form chosen over `/typeform` because `/typeform` would be ambiguous as the skill set grows. Matches existing gstack naming (`/context-save`, `/land-and-deploy`). Future sibling skills (`/typeform-list`, `/typeform-responses`, `/typeform-update`) can be added without collision.

**Optional flags:**
- `--brand <name>` — explicit brand override
- `--workspace <id>` — explicit workspace override (rarely needed)
- `--no-logo` — skip the logo upload step (debugging / one-off use)

**No flags required.** The skill works from natural-language input alone.

## Error handling

The skill must not silently fail. For each external call, on failure it reports:
- What was attempted
- The HTTP status + Typeform's error description
- Whether the failure is fatal or recoverable
- What the user can do next

The two known-risky calls:
- `POST /images` — degrades gracefully (see Branding section)
- `POST /themes` — if it fails during bootstrap, the skill falls back to creating the form against Typeform's default theme and tells the user the theme will need to be applied manually

All other failures (form POST itself, auth, network) abort with a clear message.

## Open questions deferred to implementation

- Exact wording of the wizard's question sequence — to be drafted during skill writing, tuned over first ~3 real uses
- Sunkissed brand bootstrap path: which file in `naptic-content-engine/` or `omerta-cortex/` is canonical for Sunkissed brand specs — to be discovered during implementation
- Plugin manifest format (`.claude-plugin/plugin.json` schema) — Jordan's review will confirm we match the gstack/superpowers convention before publishing
- Whether to expose a `/typeform-setup` helper command for first-time token configuration, or just rely on the skill's error messages to guide users — defer; start with error-message guidance, add a setup command if friction is real

## Initial implementation order (high level — full plan comes from writing-plans)

1. Rename existing `~/.config/typeform/token` → `omerta.token` on Darien's machine
2. Create `NapticStacks/naptic-claude-skills` repo with plugin skeleton + README + plugin.json
3. Move this `DESIGN.md` into the repo at `skills/typeform-create/DESIGN.md`
4. Write SKILL.md and mode prompts (wizard, spec, sketch)
5. Write helpers + api-reference + brand-resolver
6. Seed `brand-registry/brands.json` with Omertá (using current known IDs) and Sunkissed (with discovered colors/voice notes, `theme_id: null`)
7. Self-test: Darien installs the plugin locally, runs `/typeform-create` end-to-end in all three modes against the Omertá account, fixes anything brittle
8. Jordan 5-min review of plugin repo structure
9. Announce in team Slack with install instructions

## Resume command

Run this from inside Claude Code (no `claude` prefix) to continue from the implementation plan:

```
/superpowers:writing-plans Read the design at ~/.claude/skills/typeform-create/DESIGN.md and produce an implementation plan. Target: build a Claude Code plugin shipped from NapticStacks/naptic-claude-skills (new repo) containing the typeform-create skill at skills/typeform-create/. Token for Omertá is currently at ~/.config/typeform/token and will be renamed to omerta.token as step 1. Omertá theme M9lt1iSI and workspace cahxDC already exist in Alex's Typeform account. Plan should include the 9-step order from the design doc plus the testing, Jordan review, and team announcement steps.
```
