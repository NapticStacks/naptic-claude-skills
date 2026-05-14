# Typeform-Create Skill Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a Claude Code plugin from a new `NapticStacks/naptic-claude-skills` GitHub repo containing the `/typeform-create` skill — a brand-aware, three-mode (wizard/spec/sketch) Typeform creator usable by Darien, Jordan, Ben, and the rest of the Naptic team.

**Architecture:** Plugin repo at `NapticStacks/naptic-claude-skills` ships markdown skill instructions + a thin bash helper. The skill routes invocations to one of three modes based on the user's input. All Typeform API calls go through `helpers/build-form.sh` reading per-brand tokens from `~/.config/typeform/<brand>.token` (never in the repo). Brand metadata (colors, voice notes, workspace IDs, baked theme IDs for known-good accounts) ships in `brand-registry/brands.json`. Theme IDs that don't apply to the current user's account fall through to an auto-bootstrap path that creates the theme on demand and caches the result locally at `~/.config/typeform/local-themes.json`.

**Tech Stack:** Claude Code skill format (markdown with YAML frontmatter), Bash 3.2+ (compat with macOS default), curl, jq (already installed on Darien's machine), gh CLI (already authenticated), Typeform Create API v3.

**Reference:** Design doc at `/Users/darienbodenhorst/.claude/skills/typeform-create/DESIGN.md` (will move into the plugin repo in Task 2).

---

## File Inventory (created by this plan)

**In the new plugin repo:**
- `README.md`
- `LICENSE` (MIT)
- `.claude-plugin/plugin.json`
- `skills/typeform-create/SKILL.md`
- `skills/typeform-create/DESIGN.md` (moved from local)
- `skills/typeform-create/brand-resolver.md`
- `skills/typeform-create/api-reference.md`
- `skills/typeform-create/modes/wizard.md`
- `skills/typeform-create/modes/spec.md`
- `skills/typeform-create/modes/sketch.md`
- `skills/typeform-create/helpers/build-form.sh`
- `brand-registry/brands.json`

**On Darien's machine (local config, never in repo):**
- Rename: `~/.config/typeform/token` → `~/.config/typeform/omerta.token`
- Created on first skill run: `~/.config/typeform/local-themes.json`, `~/.config/typeform/inventor-log.md`

---

## Task 0: Pre-flight checks

**Files:** none (verification only)

- [ ] **Step 0.1: Verify the existing token is still valid**

```bash
TOKEN=$(cat ~/.config/typeform/token)
curl -sS -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $TOKEN" https://api.typeform.com/me
```

Expected: `200`. If `401`, the token has been rotated — get a fresh one from https://admin.typeform.com/account#/section/tokens, paste it into the file, then proceed.

- [ ] **Step 0.2: Rename the token file to its per-brand name**

```bash
mv ~/.config/typeform/token ~/.config/typeform/omerta.token
chmod 600 ~/.config/typeform/omerta.token
ls -la ~/.config/typeform/
```

Expected: `omerta.token` exists with `-rw-------` permissions. The old `token` filename is gone.

- [ ] **Step 0.3: Verify gh CLI is authenticated and has NapticStacks access**

```bash
gh auth status
gh api orgs/NapticStacks -q .login
```

Expected: `gh auth status` says "Logged in to github.com"; the second command prints `NapticStacks`. If the second command 404s, you don't have org membership visibility — confirm with Jordan before proceeding.

- [ ] **Step 0.4: Verify gh has `repo` scope (needed to create the new repo)**

```bash
gh auth status 2>&1 | grep -i "Token scopes"
```

Expected: output includes `repo` scope. If missing, run `gh auth refresh -s repo` and re-auth.

- [ ] **Step 0.5: Verify jq is installed**

```bash
which jq && jq --version
```

Expected: a path and a version. If missing: `brew install jq`.

---

## Task 1: Create the plugin repo with skeleton

**Files:**
- Create: `~/github/naptic-claude-skills/README.md`
- Create: `~/github/naptic-claude-skills/LICENSE`
- Create: `~/github/naptic-claude-skills/.claude-plugin/plugin.json`
- Create: `~/github/naptic-claude-skills/.gitignore`

- [ ] **Step 1.1: Create the local repo directory and initialize git**

```bash
mkdir -p ~/github/naptic-claude-skills/.claude-plugin
mkdir -p ~/github/naptic-claude-skills/skills/typeform-create/modes
mkdir -p ~/github/naptic-claude-skills/skills/typeform-create/helpers
mkdir -p ~/github/naptic-claude-skills/brand-registry
cd ~/github/naptic-claude-skills && git init -b main
```

Expected: `Initialized empty Git repository ...` and the directory tree exists.

- [ ] **Step 1.2: Write `.gitignore`**

Path: `~/github/naptic-claude-skills/.gitignore`

```
.DS_Store
*.log
node_modules/
.env
.env.*
```

- [ ] **Step 1.3: Write `LICENSE` (MIT)**

Path: `~/github/naptic-claude-skills/LICENSE`

```
MIT License

Copyright (c) 2026 NapticStacks

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 1.4: Write `.claude-plugin/plugin.json`**

Path: `~/github/naptic-claude-skills/.claude-plugin/plugin.json`

```json
{
  "name": "naptic-claude-skills",
  "version": "0.1.0",
  "description": "Naptic team Claude Code skills — shared utilities for Darien, Jordan, Ben and the team.",
  "author": "Naptic",
  "license": "MIT",
  "repository": "https://github.com/NapticStacks/naptic-claude-skills",
  "skills": [
    "skills/typeform-create"
  ]
}
```

**Note for the executor:** the exact schema for `.claude-plugin/plugin.json` is what Jordan will confirm in Task 13. If the gstack/superpowers convention differs (e.g., uses `manifest.json` or a different field name like `entry`), adjust to match in Task 13 — for now, write it as above to unblock progress.

- [ ] **Step 1.5: Write `README.md`**

Path: `~/github/naptic-claude-skills/README.md`

````markdown
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
````

- [ ] **Step 1.6: First commit**

```bash
cd ~/github/naptic-claude-skills
git add .
git status
git commit -m "init: scaffold naptic-claude-skills plugin repo"
```

Expected: the commit lists README.md, LICENSE, .gitignore, .claude-plugin/plugin.json.

- [ ] **Step 1.7: Create the remote repo on NapticStacks org and push**

```bash
gh repo create NapticStacks/naptic-claude-skills \
  --public \
  --description "Naptic team Claude Code skills" \
  --source=. \
  --remote=origin \
  --push
```

If the team prefers private, swap `--public` for `--private`. Check with Darien on visibility before running if unsure.

Expected: repo created, push succeeds. Verify with `gh repo view NapticStacks/naptic-claude-skills`.

---

## Task 2: Move DESIGN.md into the plugin repo

**Files:**
- Move: `/Users/darienbodenhorst/.claude/skills/typeform-create/DESIGN.md` → `~/github/naptic-claude-skills/skills/typeform-create/DESIGN.md`

- [ ] **Step 2.1: Copy the design doc into the repo**

```bash
cp /Users/darienbodenhorst/.claude/skills/typeform-create/DESIGN.md \
   ~/github/naptic-claude-skills/skills/typeform-create/DESIGN.md
```

- [ ] **Step 2.2: Delete the local copy (now redundant)**

```bash
rm /Users/darienbodenhorst/.claude/skills/typeform-create/DESIGN.md
# Keep PLAN.md locally during execution; it'll move into the repo at Task 14
```

- [ ] **Step 2.3: Commit**

```bash
cd ~/github/naptic-claude-skills
git add skills/typeform-create/DESIGN.md
git commit -m "docs(typeform-create): import design doc from brainstorm session"
```

---

## Task 3: Write `SKILL.md` (main skill entry point)

**Files:**
- Create: `~/github/naptic-claude-skills/skills/typeform-create/SKILL.md`

- [ ] **Step 3.1: Write `SKILL.md`**

Path: `~/github/naptic-claude-skills/skills/typeform-create/SKILL.md`

````markdown
---
name: typeform-create
description: Create branded Typeforms via natural language. Three modes (wizard, spec, sketch) auto-detected from input. Brand-aware (Omertá, Sunkissed pre-seeded; new brands learned on demand). Use when asked to "create a typeform", "make a typeform", "build a form", "intake form", or any variant. Pulls per-brand tokens from `~/.config/typeform/<brand>.token` and brand metadata from the plugin's `brand-registry/brands.json`. (naptic-claude-skills)
---

# /typeform-create

Create production-ready Typeforms by talking to me in plain English. I'll figure out which mode you're in and walk the right path.

## How to invoke

Just describe what you want. Examples:

- `/typeform-create I want a form to qualify Omertá members for our experiences`
- `/typeform-create here's the spec from Alex: [paste]`
- `/typeform-create lead intake for real estate buyers in Asheville`
- `/typeform-create make me a typeform`  (I'll ask)

## Mode selection (do this first)

Read the user's prompt and pick exactly one mode. Do not announce the mode choice — just route silently.

**Spec mode** — pick this when the user has pasted a full structured form spec, with at least two of:
- Numbered/named pages or sections (`PAGE 1`, `Section A`, `Intro`)
- Multiple-choice options visible (lines starting with `-` or `•` under a question)
- An explicit list of fields with labels
- Welcome screen + thank-you screen copy

→ Load `modes/spec.md` and follow it.

**Wizard mode** — pick this when input is sparse (one short sentence or empty), the user explicitly asks for help ("walk me through it", "I don't know what I want"), or there's no described purpose.

→ Load `modes/wizard.md` and follow it.

**Sketch mode** — pick this when there's a clear goal/audience but no field structure ("intake for X", "form to qualify Y", "survey to find Z").

→ Load `modes/sketch.md` and follow it.

If genuinely ambiguous, ask one question: *"Quick check — do you want me to walk you through field-by-field (wizard), draft a proposed structure for you to review (sketch), or do you have a full spec to paste (spec)?"*

## Brand resolution (do this second, before building)

Load `brand-resolver.md` and follow it. Output: a resolved brand object containing token path, theme ID (or null if bootstrap needed), workspace ID, logo path, colors, voice notes.

If brand resolution fails (no token, no registry entry, ambiguous), stop and tell the user exactly what to do.

## API reference

For every Typeform HTTP call you make, follow `api-reference.md`. Use `helpers/build-form.sh` for the form-creation POST so error handling stays consistent.

## After successful form creation

Do all of the following in order:

1. Print the public URL (`https://form.typeform.com/to/<form_id>`) and the edit URL (`https://admin.typeform.com/form/<form_id>/create`).
2. Append an entry to `~/.config/typeform/inventor-log.md` (create the file if missing). Entry format:

```
---
timestamp: <ISO 8601>
user: <`git config user.name` || `whoami`>
mode: <wizard|spec|sketch>
brand: <brand key>
form_title: <title>
form_id: <id>
public_url: <url>
prompt: |
  <user's original prompt, verbatim, indented two spaces>
decisions:
  - <any non-trivial choice the skill made, e.g. "made social link optional", "added 18+ age gate">
---
```

3. Offer two follow-ups: (a) preview the form yourself on desktop and mobile, (b) want me to draft a Slack post for Alex/Jay/team announcing it?

## What NOT to do

- Do not invent Typeform field types that aren't in `api-reference.md`. Stick to: `short_text`, `long_text`, `multiple_choice`, `email`, `phone_number`, `number`, `website`, `date`, `statement`.
- Do not silently default unspecified fields to required. In wizard/sketch modes, ask explicitly when in doubt; in spec mode, follow what the user wrote.
- Do not paste tokens into chat output, log files, or commits. Tokens are read from `~/.config/typeform/<brand>.token` and used only in `Authorization: Bearer` headers.
- Do not attempt to edit or update an existing form — that's out of scope for v1.

## Flags (optional)

- `--brand <key>` — override brand detection (e.g., `--brand sunkissed`)
- `--workspace <id>` — override workspace ID
- `--no-logo` — skip the logo upload step
````

- [ ] **Step 3.2: Commit**

```bash
cd ~/github/naptic-claude-skills
git add skills/typeform-create/SKILL.md
git commit -m "feat(typeform-create): add SKILL.md with mode-routing and post-creation flow"
```

---

## Task 4: Write the three mode files

**Files:**
- Create: `~/github/naptic-claude-skills/skills/typeform-create/modes/wizard.md`
- Create: `~/github/naptic-claude-skills/skills/typeform-create/modes/spec.md`
- Create: `~/github/naptic-claude-skills/skills/typeform-create/modes/sketch.md`

- [ ] **Step 4.1: Write `modes/spec.md`**

Path: `~/github/naptic-claude-skills/skills/typeform-create/modes/spec.md`

````markdown
# Spec Mode

The user has pasted a complete structured form spec. Your job is to translate it into a Typeform Create API payload faithfully — not to redesign it.

## Procedure

1. **Identify the structure.** Walk through the pasted spec and extract:
   - Form title (usually the first big heading or "PAGE 1 — INTRO" title)
   - Welcome screen title + description + button text (from intro/page 1)
   - Each field: type, title, options if applicable, whether required
   - Thank-you screen title + description (from the final/closing page)

2. **Map field types.** Translate user-language labels to Typeform types:
   - "Full Name", "Name" → `short_text`
   - "Email", "Email Address" → `email`
   - "Phone", "WhatsApp" → `phone_number` (set `default_country_code` to "US" unless told otherwise)
   - "Instagram", "Social Media", "Link", "URL" → `short_text` (NOT `website`, which validates strict URL format and breaks for `@username`)
   - "Age", any standalone number → `number` (set sensible `min_value`/`max_value` if applicable, e.g. age 18–99)
   - Multiple-choice lists: `multiple_choice` (single-select unless the spec says "Select all that apply" or "Multiple Selection", in which case set `allow_multiple_selection: true`)
   - Long open-ended questions: `long_text`
   - Short open-ended: `short_text`

3. **Ask at most one clarifying question** — only if the spec has genuine ambiguity that you cannot resolve from context. Examples of ambiguity worth asking about:
   - Pricing/payment language that could be policy-sensitive ("non-member pricing 35% higher" — confirm public visibility)
   - Age gates with no explicit minimum
   - Fields that look optional but aren't explicitly marked

   Do NOT ask about formatting choices (em dashes, hyphens), default styling, or anything obviously stylistic. Default to faithful reproduction of the user's text.

4. **Resolve the brand.** Follow `brand-resolver.md`. If the spec mentions a brand name, that takes priority; otherwise fall back to the registry default.

5. **Build the payload.** Use the patterns in `api-reference.md`. Run it through `helpers/build-form.sh`.

6. **After successful creation,** follow the "After successful form creation" section in `SKILL.md`.

## What to preserve verbatim from the user's spec

- Question wording (do not rewrite or "improve" their phrasing)
- Option labels (including em dashes, special characters)
- Welcome and thank-you screen copy
- Order of fields and pages

## What to apply silently

- Brand theme (from registry)
- Logo upload (from registry's `logo_path`)
- Sensible default settings: `progress_bar: proportion`, `show_progress_bar: true`, `meta.allow_indexing: false`
````

- [ ] **Step 4.2: Write `modes/wizard.md`**

Path: `~/github/naptic-claude-skills/skills/typeform-create/modes/wizard.md`

````markdown
# Wizard Mode

The user has minimal input and wants to be walked through creating a form. Ask one question at a time. Keep momentum.

## Procedure

Ask these in order. After each answer, summarize what you've collected so far in one short line ("Got it — Omertá form titled 'X' for buyers, dark theme. Next:") so the user feels progress.

### Step 1: Purpose + audience

Ask: *"What's this form for, and who's filling it out? One or two sentences is plenty."*

Use the answer to infer the brand (see `brand-resolver.md`) and to seed sensible defaults later.

### Step 2: Form title + welcome copy

Ask: *"What should I call the form? And one short line for the welcome screen describing what it's for to the person filling it out."*

### Step 3: Fields, one at a time

Ask: *"Okay — what's the first thing you need to know about each person? Tell me the question and the answer type (text / email / phone / multiple choice / number / paragraph). Say 'done' when you've named the last one."*

For each field, ask follow-ups only if needed:
- Multiple choice → "What are the options? List them comma-separated."
- Multiple choice with multi-select → "One choice or many?"
- Required by default → ask once globally: "Should all of these be required, or just specific ones?"

Keep this loop tight. The user can refine in the Typeform UI after.

### Step 4: Existing-form reference (only if user seems uncertain)

If the user struggles to name fields, offer:

> "Want me to show you what we've built for other forms in this account? Might give you a template to riff on."

If yes, call `GET /forms?workspace_id=<resolved>` (see `api-reference.md`) and surface up to 3 existing forms by title and field count. Let them pick one to use as a structural reference (not a clone).

### Step 5: Closing copy

Ask: *"Anything specific for the thank-you screen, or want me to use the default 'Application received. We'll be in touch.'?"*

### Step 6: Brand confirmation

If brand resolution from Step 1 was confident, skip. Otherwise ask: *"Which brand is this — Omertá, Sunkissed, or something else?"*

### Step 7: Build

Use `helpers/build-form.sh`. Then follow the "After successful form creation" section in `SKILL.md`.

## Tone rules for wizard mode

- One question per turn. No multi-part questions.
- Confirm progress in short asides ("Got it.", "Adding that.").
- If the user gives a one-word answer that's ambiguous, ask one targeted follow-up — don't assume.
- If the user says "done" while a step is incomplete, ask if they want to skip it or fill it in.
````

- [ ] **Step 4.3: Write `modes/sketch.md`**

Path: `~/github/naptic-claude-skills/skills/typeform-create/modes/sketch.md`

````markdown
# Sketch Mode

The user has a goal ("intake for buyer leads", "qualify Omertá applicants") but no field structure. Your job is to propose a structure they'll recognize as right, then iterate.

## Procedure

### Step 1: Acknowledge + ask about audience (one turn)

Briefly restate the goal, then ask one clarifying question about audience or use case. Example:

> "Got it — qualification intake for Omertá experiences. Quick check: who's going to receive these — strictly people you've personally invited, or are you also taking inbound from Jay's promotion?"

### Step 2: Reference existing forms (if any)

Call `GET /forms?workspace_id=<resolved-from-brand>` and look at what already exists. If a similar-purpose form is present, draw from its structure (NOT verbatim — use as inspiration).

### Step 3: Draft a structure (as a preview, not a build)

Output a page-by-page proposal. Format:

```
Here's what I'm thinking — review and tell me what to change:

PAGE 1 — Intro
  Title: [proposed title]
  Description: [proposed 2-3 sentence welcome]
  Button: [proposed CTA]

PAGE 2 — [section name, e.g. "Personal info"]
  • [field name] — [type] [required?]
  • [field name] — [type] [required?]
  ...

PAGE 3 — [section name]
  ...

PAGE N — Thank you
  Description: [proposed thank-you copy]

Net: [count] questions, [estimated minutes] to fill out.
```

### Step 4: Take feedback

Wait for the user's response. Common edits:
- "Drop X, add Y"
- "Make Z optional"
- "Reorder these"
- "Sounds good, build it"

Iterate until the user approves. Resist pushing toward build before they explicitly say go — sketch mode is the opposite of spec mode.

### Step 5: Build

Once approved, treat the iterated draft as a spec and proceed exactly like spec mode (use `modes/spec.md` for the build mechanics). Use `helpers/build-form.sh`. Follow the "After successful form creation" section in `SKILL.md`.

## When to suggest scope changes

If the user's goal implies more fields than they realize they need (e.g., they say "qualify applicants" but don't mention net worth, age, or geography), include those in the draft but flag each one as a suggestion they can drop:

```
  • Net worth range — multiple choice (suggested — drop if you don't want to ask)
```

Lets them choose without making them argue.
````

- [ ] **Step 4.4: Commit**

```bash
cd ~/github/naptic-claude-skills
git add skills/typeform-create/modes/
git commit -m "feat(typeform-create): add wizard/spec/sketch mode prompts"
```

---

## Task 5: Write `brand-resolver.md`

**Files:**
- Create: `~/github/naptic-claude-skills/skills/typeform-create/brand-resolver.md`

- [ ] **Step 5.1: Write the file**

Path: `~/github/naptic-claude-skills/skills/typeform-create/brand-resolver.md`

````markdown
# Brand Resolver

Resolves which brand a form belongs to and assembles all the metadata needed to build it.

## Inputs

- The user's prompt (plain text)
- Optional `--brand <key>` flag
- The shipped brand registry: `<plugin-root>/brand-registry/brands.json`
- The user's local theme cache: `~/.config/typeform/local-themes.json` (may not exist yet)
- The user's tokens: `~/.config/typeform/<brand>.token`

## Output

A resolved brand object with these keys:
- `brand_key`: the lowercase identifier ("omerta", "sunkissed", etc.)
- `display_name`: the prettified name ("Omertá")
- `token`: the bearer token string (read from `~/.config/typeform/<brand_key>.token`)
- `workspace_id`: Typeform workspace ID
- `theme_id`: Typeform theme ID for this account+brand (may require bootstrap)
- `logo_path`: absolute path to the brand logo (or null)
- `voice_notes`: free-form string passed to Claude as context during build

## Resolution order

1. If `--brand <key>` flag is present, use it directly. Skip detection.

2. Scan the user's prompt (case-insensitive) for any of these substrings, in this priority:
   - "omertá", "omerta"  → `omerta`
   - "sunkissed", "sun kissed", "sun-kissed"  → `sunkissed`
   - (more brands added as the registry grows)

3. If exactly one brand matched, use it.

4. If multiple matched, ask the user: *"Which brand is this for — Omertá or Sunkissed?"*

5. If none matched, use the registry's `default` value (currently `omerta`). Tell the user once: *"I'll create this in the Omertá account by default — say so if you meant a different brand."*

## Assembling the resolved object

1. Read the brand entry from `brand-registry/brands.json`.

2. **Token lookup:** open `~/.config/typeform/<brand_key>.token`. If missing or empty, STOP and print:

```
No <brand_key>.token found at ~/.config/typeform/.

To set it up:
  1. Get the <display_name> Typeform personal access token from the brand owner
     (Omertá: Alex or Darien; Sunkissed: Joey or Darien)
  2. Save it to ~/.config/typeform/<brand_key>.token
  3. chmod 600 ~/.config/typeform/<brand_key>.token
  4. Re-run.
```

3. **Theme ID resolution:**
   - First, check `~/.config/typeform/local-themes.json` for a cached `<brand_key>` entry. If present, use it (then run "verify still exists" below).
   - Else, check the shipped `brands.json` for a `theme_id` (non-null). If present, use it.
   - Else, BOOTSTRAP: see "Theme bootstrap" section below.

4. **Verify the theme still exists:** call `GET https://api.typeform.com/themes/<theme_id>` with the brand's token. If 200, proceed. If 404 (theme deleted), drop the cached entry and BOOTSTRAP.

5. **Workspace ID:** from the registry. If null, BOOTSTRAP: ask the user which workspace to use; offer to create one via `POST /workspaces` if they want a new one.

## Theme bootstrap

Triggered when no valid theme ID exists for this brand in this account.

1. Read color, font, and (optionally) logo info from the registry entry.

2. If any of `colors`, `font`, or `voice_notes` are missing or stub values, attempt to discover them from canonical project locations:
   - `~/github/omerta-cortex/spvs/<brand>-membership/04-assets-index/brand/`
   - `~/github/naptic-content-engine/brands/<brand>/`
   - If none found, ask the user inline: *"I don't have Sunkissed colors saved yet. What's the main background hex? Main text/accent hex? Font name from Typeform's font list?"*

3. POST to `https://api.typeform.com/themes` with the resolved values. Capture the returned `id`.

4. Save the new theme_id to `~/.config/typeform/local-themes.json`:

```json
{
  "<brand_key>": "<theme_id>"
}
```

(Create the file if missing; merge if already populated.)

5. If brand metadata was newly discovered (colors, voice_notes, etc.), suggest the user open a PR to `brand-registry/brands.json` so the team benefits. Do NOT auto-commit.

## Unknown-brand path

If the user mentions a brand not in the registry (e.g., "for NextHome"), ask three questions in one turn:

> "I don't have NextHome set up yet. To save this brand for next time:
> 1. Hex codes (background + accent)?
> 2. Path to a logo (or just say 'skip')?
> 3. Workspace — same Typeform account as Omertá, or different? If different, you'll need a separate `nexthome.token` first."

Then write the new entry to `~/.config/typeform/local-themes.json` AND suggest the PR to `brand-registry/brands.json`.
````

- [ ] **Step 5.2: Commit**

```bash
cd ~/github/naptic-claude-skills
git add skills/typeform-create/brand-resolver.md
git commit -m "feat(typeform-create): add brand resolver with theme bootstrap path"
```

---

## Task 6: Write `api-reference.md`

**Files:**
- Create: `~/github/naptic-claude-skills/skills/typeform-create/api-reference.md`

- [ ] **Step 6.1: Write the file**

Path: `~/github/naptic-claude-skills/skills/typeform-create/api-reference.md`

````markdown
# Typeform API Reference

Patterns for every Typeform Create API call this skill makes. Verified against the API as of 2026-05-13.

Base URL: `https://api.typeform.com`
Auth header: `Authorization: Bearer <token>`
Content-Type for writes: `application/json`

## Verify token

```bash
curl -sS -H "Authorization: Bearer $TOKEN" https://api.typeform.com/me
```

Returns `{"user_id": "...", "email": "...", "alias": "..."}` on success.

## List workspaces

```bash
curl -sS -H "Authorization: Bearer $TOKEN" https://api.typeform.com/workspaces
```

Returns `{"items": [{"id": "<workspace_id>", "name": "...", ...}], ...}`.

## List forms in a workspace

```bash
curl -sS -H "Authorization: Bearer $TOKEN" \
  "https://api.typeform.com/forms?workspace_id=<workspace_id>&page_size=20"
```

Returns `{"items": [{"id": "...", "title": "...", ...}], ...}`. Use for past-form reference (wizard/sketch modes).

## Fetch one form (for structural reference)

```bash
curl -sS -H "Authorization: Bearer $TOKEN" "https://api.typeform.com/forms/<form_id>"
```

Returns the full form including fields, welcome/thank-you screens, theme reference.

## Create a theme

```bash
curl -sS -X POST https://api.typeform.com/themes \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "<brand display name>",
    "colors": {
      "question": "#F5F5F5",
      "answer": "#D4D4D4",
      "button": "#F5F5F5",
      "background": "#1A1A1A"
    },
    "font": "Libre Baskerville",
    "has_transparent_button": false,
    "visibility": "private"
  }'
```

Returns `{"id": "<theme_id>", ...}`.

**Known schema quirks (gotchas from the validation error trail on 2026-05-08):**
- Do NOT pass `rounded_corners` as a boolean — it's a string enum.
- Do NOT pass `screens_font_size` or `fields_font_size` at the top level — they're nested under `screens` / `fields` objects if you set them at all.
- The `background` field, if present, requires an `href` (background image). Omit entirely for a solid color background — use the `colors.background` hex instead.

## Verify a theme exists

```bash
curl -sS -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $TOKEN" \
  https://api.typeform.com/themes/<theme_id>
```

`200` = exists. `404` = theme was deleted, re-bootstrap.

## Create a form

Use `helpers/build-form.sh` (it wraps this call with error handling). The raw call:

```bash
curl -sS -X POST https://api.typeform.com/forms \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data @/path/to/payload.json
```

Returns the full created form including `id` and `_links.display` (public URL). The public URL pattern is `https://form.typeform.com/to/<form_id>`.

## Form payload shape (the JSON you build before POSTing)

```json
{
  "title": "<form title>",
  "type": "form",
  "workspace": { "href": "https://api.typeform.com/workspaces/<workspace_id>" },
  "theme": { "href": "https://api.typeform.com/themes/<theme_id>" },
  "settings": {
    "language": "en",
    "is_public": true,
    "progress_bar": "proportion",
    "show_progress_bar": true,
    "show_typeform_branding": true,
    "meta": { "allow_indexing": false }
  },
  "welcome_screens": [
    {
      "ref": "welcome_intro",
      "title": "<welcome title>",
      "properties": {
        "description": "<welcome body>",
        "button_text": "Get Started",
        "show_button": true
      }
    }
  ],
  "thankyou_screens": [
    {
      "ref": "thankyou_default",
      "title": "<thanks title>",
      "properties": {
        "description": "<thanks body>",
        "show_button": false
      }
    }
  ],
  "fields": [
    /* see field types below */
  ]
}
```

## Field type templates

### `short_text`

```json
{
  "ref": "<unique-ref>",
  "title": "<question>",
  "type": "short_text",
  "validations": { "required": true, "max_length": 80 }
}
```

### `long_text`

```json
{
  "ref": "<unique-ref>",
  "title": "<question>",
  "type": "long_text",
  "validations": { "required": true, "max_length": 1000 }
}
```

### `email`

```json
{
  "ref": "<unique-ref>",
  "title": "What's your email?",
  "type": "email",
  "validations": { "required": true }
}
```

### `phone_number`

```json
{
  "ref": "<unique-ref>",
  "title": "Phone number?",
  "type": "phone_number",
  "properties": { "default_country_code": "US" },
  "validations": { "required": true }
}
```

### `number` (with min/max)

```json
{
  "ref": "<unique-ref>",
  "title": "How old are you?",
  "type": "number",
  "validations": { "required": true, "min_value": 18, "max_value": 99 }
}
```

### `multiple_choice` (single-select)

```json
{
  "ref": "<unique-ref>",
  "title": "<question>",
  "type": "multiple_choice",
  "properties": {
    "randomize": false,
    "allow_multiple_selection": false,
    "allow_other_choice": false,
    "vertical_alignment": true,
    "choices": [
      { "ref": "<choice-ref-1>", "label": "<option 1>" },
      { "ref": "<choice-ref-2>", "label": "<option 2>" }
    ]
  },
  "validations": { "required": true }
}
```

### `multiple_choice` (multi-select)

Same as above but `"allow_multiple_selection": true`. Add `"description": "Select all that apply."` to `properties` for clarity.

## Image (logo) upload

```bash
# Upload via base64 in JSON body (Typeform's preferred path for the API)
LOGO_B64=$(base64 -i <logo_path> | tr -d '\n')
curl -sS -X POST https://api.typeform.com/images \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"image\": \"$LOGO_B64\", \"file_name\": \"logo.jpg\"}"
```

Returns `{"id": "<image_id>", ...}`. Attach to the welcome screen via:

```json
"attachment": { "type": "image", "href": "https://images.typeform.com/images/<image_id>" }
```

**Graceful degradation:** if this call fails (any non-2xx), do NOT bail the whole form creation. Log the failure, create the form without the logo, and tell the user where to upload it manually (the edit URL).

## Rate limits

Typeform Create API: 2 requests/second per workspace, 60/minute per token. For interactive use this is never a problem; if you do hit a 429, sleep 2 seconds and retry once. If still 429, stop and tell the user.
````

- [ ] **Step 6.2: Commit**

```bash
cd ~/github/naptic-claude-skills
git add skills/typeform-create/api-reference.md
git commit -m "feat(typeform-create): add Typeform API reference with field templates and quirks"
```

---

## Task 7: Write `helpers/build-form.sh`

**Files:**
- Create: `~/github/naptic-claude-skills/skills/typeform-create/helpers/build-form.sh`

- [ ] **Step 7.1: Write the script**

Path: `~/github/naptic-claude-skills/skills/typeform-create/helpers/build-form.sh`

```bash
#!/usr/bin/env bash
# build-form.sh — POST a JSON payload to Typeform's create-form endpoint.
#
# Usage:
#   build-form.sh <token-file> <payload-file>
#
# Arguments:
#   token-file    Path to a file containing only the bearer token (e.g. ~/.config/typeform/omerta.token)
#   payload-file  Path to the JSON form payload
#
# On success: prints a JSON line with form_id, public_url, edit_url.
# On failure: prints diagnostic info to stderr and exits non-zero.

set -euo pipefail

TOKEN_FILE="${1:?token-file path required}"
PAYLOAD_FILE="${2:?payload-file path required}"

if [[ ! -r "$TOKEN_FILE" ]]; then
  echo "build-form.sh: cannot read token file: $TOKEN_FILE" >&2
  exit 64
fi

if [[ ! -r "$PAYLOAD_FILE" ]]; then
  echo "build-form.sh: cannot read payload file: $PAYLOAD_FILE" >&2
  exit 64
fi

TOKEN=$(tr -d '[:space:]' < "$TOKEN_FILE")
if [[ -z "$TOKEN" ]]; then
  echo "build-form.sh: token file is empty: $TOKEN_FILE" >&2
  exit 64
fi

# Validate payload is JSON before sending
if ! jq -e . < "$PAYLOAD_FILE" >/dev/null; then
  echo "build-form.sh: payload is not valid JSON: $PAYLOAD_FILE" >&2
  exit 65
fi

RESPONSE_FILE=$(mktemp)
trap 'rm -f "$RESPONSE_FILE"' EXIT

HTTP_CODE=$(curl -sS -o "$RESPONSE_FILE" -w "%{http_code}" \
  -X POST "https://api.typeform.com/forms" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data @"$PAYLOAD_FILE")

if [[ "$HTTP_CODE" != "201" && "$HTTP_CODE" != "200" ]]; then
  echo "build-form.sh: Typeform API returned HTTP $HTTP_CODE" >&2
  echo "--- response ---" >&2
  cat "$RESPONSE_FILE" >&2
  echo "" >&2
  exit 1
fi

FORM_ID=$(jq -r '.id' < "$RESPONSE_FILE")
if [[ -z "$FORM_ID" || "$FORM_ID" == "null" ]]; then
  echo "build-form.sh: response did not include an 'id' field" >&2
  cat "$RESPONSE_FILE" >&2
  exit 1
fi

jq -n \
  --arg form_id "$FORM_ID" \
  --arg public_url "https://form.typeform.com/to/$FORM_ID" \
  --arg edit_url "https://admin.typeform.com/form/$FORM_ID/create" \
  '{form_id: $form_id, public_url: $public_url, edit_url: $edit_url}'
```

- [ ] **Step 7.2: Make it executable**

```bash
chmod +x ~/github/naptic-claude-skills/skills/typeform-create/helpers/build-form.sh
```

- [ ] **Step 7.3: Quick sanity check the script with shellcheck (if installed) and a dry-run**

```bash
# If shellcheck is available, run it
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck ~/github/naptic-claude-skills/skills/typeform-create/helpers/build-form.sh
fi

# Dry-run: bad token file path should exit non-zero with a clear error
~/github/naptic-claude-skills/skills/typeform-create/helpers/build-form.sh \
  /nonexistent/token /nonexistent/payload 2>&1 || echo "exit code: $?"
```

Expected: shellcheck passes (or is not installed); the dry-run prints `cannot read token file: /nonexistent/token` and an exit code of 64.

- [ ] **Step 7.4: Commit**

```bash
cd ~/github/naptic-claude-skills
git add skills/typeform-create/helpers/build-form.sh
git commit -m "feat(typeform-create): add build-form.sh POST helper with error handling"
```

---

## Task 8: Seed `brand-registry/brands.json`

**Files:**
- Create: `~/github/naptic-claude-skills/brand-registry/brands.json`

- [ ] **Step 8.1: Discover Sunkissed brand info from existing repos**

Run these locally to find Sunkissed brand metadata. The exact paths may vary — check each, capture what's there:

```bash
# Try the locations the design doc names
ls ~/github/naptic-content-engine/brands/sunkissed/ 2>/dev/null
ls ~/github/omerta-cortex/spvs/sunkissed*/ 2>/dev/null
ls ~/github/sunkissed*/ 2>/dev/null

# Search broadly for a brand.json or similar
find ~/github -name 'brand.json' -path '*sunkissed*' 2>/dev/null
find ~/github -name 'brand.json' 2>/dev/null | head
```

From whichever file is canonical, capture:
- `colors.bg` (background hex)
- `colors.text` (primary text hex)
- `colors.accent` (accent hex)
- `font` (font name; must be one Typeform supports — see Typeform font list)
- `voice_notes` (a short prose summary of brand voice, e.g. from `brand.json`'s `language_constraints` or `voice` field)
- `logo_path` (absolute path to a logo file usable as a Typeform image)

If none of these locations have what's needed, ask Darien for the Sunkissed brand.json path inline before continuing.

- [ ] **Step 8.2: Write the brand registry file**

Path: `~/github/naptic-claude-skills/brand-registry/brands.json`

Fill in the Sunkissed values from Step 8.1. The Omertá values are known and locked in below.

```json
{
  "default": "omerta",
  "brands": {
    "omerta": {
      "display_name": "Omertá",
      "theme_id": "M9lt1iSI",
      "workspace_id": "cahxDC",
      "workspace_name": "omerta travel",
      "logo_path": "~/Pictures/Omerta-Brand/omerta-logo.jpg",
      "colors": {
        "bg": "#1A1A1A",
        "text": "#F5F5F5",
        "accent": "#D4D4D4"
      },
      "font": "Libre Baskerville",
      "voice_notes": "Sophisticated, monochrome luxury. Em dashes OK on public-facing forms. No emojis. Anonymous tone."
    },
    "sunkissed": {
      "display_name": "Sunkissed",
      "theme_id": null,
      "workspace_id": null,
      "logo_path": "<FILL FROM STEP 8.1>",
      "colors": {
        "bg": "<FILL FROM STEP 8.1>",
        "text": "<FILL FROM STEP 8.1>",
        "accent": "<FILL FROM STEP 8.1>"
      },
      "font": "<FILL FROM STEP 8.1 — must be in Typeform's font list>",
      "voice_notes": "<FILL FROM STEP 8.1>"
    }
  }
}
```

**Important:** the executor must replace every `<FILL FROM STEP 8.1>` with real values before committing. Do not commit placeholders. If Step 8.1 surfaced no canonical source, stop and ask Darien — do not invent values.

- [ ] **Step 8.3: Validate the JSON**

```bash
jq -e . < ~/github/naptic-claude-skills/brand-registry/brands.json >/dev/null && echo "OK" || echo "INVALID"
```

Expected: `OK`.

- [ ] **Step 8.4: Commit**

```bash
cd ~/github/naptic-claude-skills
git add brand-registry/brands.json
git commit -m "feat(brand-registry): seed Omertá (full) and Sunkissed (theme_id pending bootstrap)"
```

---

## Task 9: Local install + self-test (spec mode)

**Files:** none modified — runtime verification only.

- [ ] **Step 9.1: Install the plugin locally for Darien**

From inside Claude Code (a fresh session is fine):

```
/plugin install NapticStacks/naptic-claude-skills
```

Expected: plugin installs without error, and `/typeform-create` appears in the skill list (run `/help` or check the slash-command autocomplete).

If `/plugin install` doesn't recognize the structure, fall back to:

```bash
# Symlink as a local-development plugin
ln -s ~/github/naptic-claude-skills ~/.claude/plugins/naptic-claude-skills
```

Then restart Claude Code.

- [ ] **Step 9.2: Run `/typeform-create` in spec mode against a known-good paste**

Use this test input (copy-paste verbatim):

```
/typeform-create PAGE 1 — INTRO
Title: Test — Spec Mode Smoke Test
Description: Verifying spec mode end-to-end.
Button: Start

PAGE 2 — FIELDS
What's your name? — short text, required
What's your email? — email, required
Pick one — multiple choice (Option A, Option B)

PAGE 3 — THANKS
Description: Thanks — this was just a test.

This is for Omertá.
```

Expected: skill creates a form titled "Test — Spec Mode Smoke Test", returns a public URL, edit URL, and writes an inventor-log entry.

- [ ] **Step 9.3: Open the form and verify visually**

Open the public URL in a browser. Confirm:
- Welcome screen has the test title and description
- Three fields appear in order with the right types
- Dark Omertá theme applied (background ~#1A1A1A, light text)
- Thank-you screen shows the test description

If the logo upload step ran, verify the Omertá ring appears above the welcome title. If not, the skill should have warned that logo upload failed.

- [ ] **Step 9.4: Delete the test form via Typeform UI**

Go to https://admin.typeform.com/form/<form_id>/create and delete it. (Don't burn response slots on test forms.)

---

## Task 10: Self-test (wizard mode)

- [ ] **Step 10.1: Run `/typeform-create` with sparse input**

```
/typeform-create make me a typeform
```

Expected: the skill enters wizard mode, asks one question at a time, walks through purpose → title → fields → branding → closing. Answer the prompts with simple test data ("Test wizard form", "I want to know names and emails", etc.). Confirm the skill never asks two questions at once.

- [ ] **Step 10.2: Verify the form was created and matches the wizard inputs**

Same checks as Step 9.3. Delete the test form when done.

---

## Task 11: Self-test (sketch mode)

- [ ] **Step 11.1: Run `/typeform-create` with goal-only input**

```
/typeform-create lead intake form for real estate buyers in Asheville
```

Expected: the skill drafts a page-by-page proposal, waits for feedback before building.

- [ ] **Step 11.2: Provide one round of feedback**

Reply with: *"Looks good but drop the age question and add a budget range field."*

Expected: the skill updates the draft and shows it again before building.

- [ ] **Step 11.3: Approve and verify build**

Reply: *"Build it."* — confirm the resulting form has the feedback applied. Delete the test form when done.

---

## Task 12: Bug fixes from self-tests

**Files:** any of the skill files that need patching.

- [ ] **Step 12.1: Collect issues**

Make a short list of anything that went wrong during Tasks 9–11. Common categories:
- Mode misdetection (skill picked the wrong mode for an input)
- Field-type mapping errors
- Tone issues in wizard prompts
- API call failures (token, theme, image upload)
- Brand registry data issues

- [ ] **Step 12.2: Patch and re-run**

For each issue, find the source (usually one of the mode files, brand-resolver.md, or api-reference.md), fix, commit with a focused message:

```bash
cd ~/github/naptic-claude-skills
git add <file>
git commit -m "fix(typeform-create): <what was wrong>"
```

Re-run the affected mode self-test from Tasks 9–11 to verify.

- [ ] **Step 12.3: Push everything to the remote**

```bash
cd ~/github/naptic-claude-skills
git push origin main
```

---

## Task 13: Jordan plugin-structure review

**Files:** none (review checkpoint).

- [ ] **Step 13.1: Send Jordan the repo URL with a focused ask**

Slack DM Jordan (Mayday workspace, his usual channel — Darien knows):

> "Built a shared Claude Code plugin for the team: https://github.com/NapticStacks/naptic-claude-skills
>
> First skill is `/typeform-create`. Before I tell Ben to install it, can you do a 5-min pass on the plugin repo structure to confirm it matches the gstack/superpowers convention you're using? Specifically:
> - Is `.claude-plugin/plugin.json` the right manifest name + schema?
> - Anything else missing for `/plugin install` to work cleanly across the team?
>
> No need to review the skill content — just the plugin wiring."

- [ ] **Step 13.2: Apply Jordan's feedback**

If he flags structural issues, fix them. Common likely findings:
- Manifest file should be named differently
- Plugin needs an additional file (e.g., `marketplace.json`)
- Version pinning convention

Commit fixes with `fix(plugin): <change> per Jordan review`, push.

- [ ] **Step 13.3: Re-verify install works**

In a fresh Claude Code session (uninstall first if necessary), run `/plugin install NapticStacks/naptic-claude-skills` and confirm clean install. Run one of the self-tests again as a smoke check.

---

## Task 14: Move PLAN.md into the repo + tag v0.1.0

- [ ] **Step 14.1: Move this plan file into the repo for posterity**

```bash
mkdir -p ~/github/naptic-claude-skills/skills/typeform-create/
mv /Users/darienbodenhorst/.claude/skills/typeform-create/PLAN.md \
   ~/github/naptic-claude-skills/skills/typeform-create/PLAN.md
cd ~/github/naptic-claude-skills
git add skills/typeform-create/PLAN.md
git commit -m "docs(typeform-create): import implementation plan"
```

- [ ] **Step 14.2: Remove the now-empty local skill directory**

```bash
rmdir /Users/darienbodenhorst/.claude/skills/typeform-create 2>/dev/null || true
```

- [ ] **Step 14.3: Tag the release**

```bash
cd ~/github/naptic-claude-skills
git tag -a v0.1.0 -m "Initial release: /typeform-create skill"
git push origin main --tags
```

Expected: tag visible at https://github.com/NapticStacks/naptic-claude-skills/releases/tag/v0.1.0.

---

## Task 15: Team Slack announcement

**Files:** none.

- [ ] **Step 15.1: Compose the announcement**

Post in the Naptic team Slack (Mayday workspace, dev/team channel — confirm with Darien which channel; likely `#dev` or similar):

> 📦 New shared Claude Code plugin: `naptic-claude-skills`
>
> First skill: `/typeform-create` — create branded Typeforms in plain English. Three modes (wizard / spec / sketch), auto-detected from how you ask. Pre-seeded for Omertá and Sunkissed.
>
> Install:
> ```
> /plugin install NapticStacks/naptic-claude-skills
> ```
>
> Per-brand setup (one-time, on your machine):
> ```bash
> mkdir -p ~/.config/typeform
> echo "tfp_..." > ~/.config/typeform/omerta.token   # get the token from Darien
> chmod 600 ~/.config/typeform/omerta.token
> ```
>
> Issues / feature requests: open against the repo. New skills welcome via PR.

(Skill rule from `SKILL.md` says no emojis on member-facing copy — this is internal team Slack, emojis are fine. Confirm with Darien before posting if unsure.)

- [ ] **Step 15.2: Post and pin**

After posting, pin the message in the channel so future team members find the install instructions easily.

- [ ] **Step 15.3: Log to inventor notebook**

Add a final entry to `~/.config/typeform/inventor-log.md` for the project itself:

```
---
timestamp: <ISO 8601>
event: project-completion
project: typeform-create skill plugin
repo: https://github.com/NapticStacks/naptic-claude-skills
version: v0.1.0
team: Darien, Jordan (reviewer), Ben (consumer)
key_design_choices:
  - three auto-detected modes (wizard/spec/sketch) rather than one
  - per-brand tokens (~/.config/typeform/<brand>.token) instead of shared
  - brand registry ships with plugin; theme IDs cached per-machine
  - graceful degradation when logo upload fails
---
```

---

## Task 16: Token rotation reminder

**Files:** none.

- [ ] **Step 16.1: Rotate the Omertá token**

Darien's Omertá token was pasted in chat on 2026-05-08 during the original form-creation session, so it's in transcript history. Rotate before publishing the plugin widely.

```bash
open https://admin.typeform.com/account#/section/tokens
```

In the Typeform UI:
1. Delete the `claude-code-omerta` (or whatever it was named) token.
2. Generate a new one with the same scopes (`forms:write`, `forms:read`, `responses:read`).
3. Save it to `~/.config/typeform/omerta.token`:
   ```bash
   read -rs -p "Paste new token: " T && printf '%s' "$T" > ~/.config/typeform/omerta.token && unset T
   chmod 600 ~/.config/typeform/omerta.token
   ```
4. Verify:
   ```bash
   curl -sS -o /dev/null -w "%{http_code}\n" \
     -H "Authorization: Bearer $(cat ~/.config/typeform/omerta.token)" \
     https://api.typeform.com/me
   ```
   Expected: `200`.

- [ ] **Step 16.2: Distribute the new token to team members who need it**

Use 1Password / Slack DM / preferred secure channel. Do NOT post in any channel that's logged or has multiple people who shouldn't have access.

---

## Self-Review

**Spec coverage** — checked each section of DESIGN.md against the plan:
- Three modes (wizard/spec/sketch) → Tasks 3, 4, 9, 10, 11
- Brand registry pre-seed (Omertá + Sunkissed) → Task 8
- Per-brand token model → Task 0.2, Task 5 (brand-resolver), README in Task 1.5
- Plugin distribution from NapticStacks repo → Task 1
- Past-form reference → covered in `modes/wizard.md` and `modes/sketch.md` (Task 4)
- Branding application + logo graceful degradation → `api-reference.md` (Task 6)
- Inventor notebook per-user → `SKILL.md` "After successful form creation" (Task 3) + project-level entry in Task 15.3
- Jordan review checkpoint → Task 13
- Team announcement → Task 15
- Token rotation (from the original session) → Task 16

**Placeholder scan** — every `<FILL FROM STEP 8.1>` in Task 8.2 is explicit and gated on a discovery step; no other placeholders. All shell commands and code blocks have concrete content. No "TBD" or "implement later" steps.

**Type consistency** — verified across tasks:
- Brand keys are lowercase strings (`omerta`, `sunkissed`) — consistent in Task 5, Task 8, Task 15
- Token file naming `<brand_key>.token` — consistent in Task 0.2, Task 5, Task 15
- Form payload field names match Typeform API (`workspace`, `theme`, `welcome_screens`, `thankyou_screens`, `fields`) — consistent in Task 6 and aligns with what worked on 2026-05-08

---

## Resume command

Run this from inside Claude Code (no `claude` prefix) to continue executing this plan in a fresh session after `/clear`:

```
/superpowers:subagent-driven-development Execute the implementation plan at /Users/darienbodenhorst/.claude/skills/typeform-create/PLAN.md. Tasks are checkbox-tracked. Starting state: the DESIGN.md is at the same directory; ~/.config/typeform/token contains the Omertá personal access token (rename to omerta.token in Task 0.2); Darien has gh CLI authenticated with NapticStacks access. Stop and ask Darien before Task 1.7 (creating the public/private repo decision), before Task 8.2 if Sunkissed discovery fails, and before Task 15.2 (which Slack channel to post in).
```
