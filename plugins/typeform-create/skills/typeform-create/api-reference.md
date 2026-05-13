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
