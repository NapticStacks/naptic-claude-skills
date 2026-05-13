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
