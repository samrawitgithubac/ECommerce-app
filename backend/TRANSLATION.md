# Amharic & English (Google Translate)

## How it works

- **UI labels** (buttons, menus): Built-in English + Amharic strings (`app_strings.dart`).
- **Product names & descriptions**: Translated via **Google Cloud Translation API** when Amharic is selected.
- **Language switch**: EN / አማ on splash, sign-in, and home header.

## Enable Google Translate (optional)

Without an API key, UI still switches to Amharic; product text stays in English.

1. Open https://console.cloud.google.com/
2. Create/select a project
3. Enable **Cloud Translation API**
4. **APIs & Services → Credentials → Create API key**
5. Add to `backend/.env`:

```env
GOOGLE_TRANSLATE_API_KEY=your_api_key_here
```

6. Restart backend: `npm start`

## API

- `GET /api/v2/translate/status` — check if Google is configured
- `POST /api/v2/translate` — body: `{ "texts": ["Hello"], "target": "am", "source": "en" }`

Requires login (Bearer token) for translate POST.
