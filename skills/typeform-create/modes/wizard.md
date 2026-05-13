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
