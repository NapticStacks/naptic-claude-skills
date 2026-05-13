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
