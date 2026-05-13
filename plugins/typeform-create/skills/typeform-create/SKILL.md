---
name: typeform-create
description: Create branded Typeforms via natural language. Three modes (wizard, spec, sketch) auto-detected from input. Brand-aware (Omertá, Sunkissed pre-seeded; new brands learned on demand). Use when asked to "create a typeform", "make a typeform", "build a form", "intake form", or any variant. Pulls per-brand tokens from ~/.config/typeform/<brand>.token and brand metadata from the plugin's brand-registry/brands.json. (naptic-claude-skills)
version: 0.1.0
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
