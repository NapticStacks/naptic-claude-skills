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
