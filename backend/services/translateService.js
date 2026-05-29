const https = require('https');

function isConfigured() {
  return Boolean(process.env.GOOGLE_TRANSLATE_API_KEY);
}

function translateRequest(texts, target, source = 'en') {
  return new Promise((resolve, reject) => {
    const key = process.env.GOOGLE_TRANSLATE_API_KEY;
    const params = new URLSearchParams();
    params.append('key', key);
    texts.forEach((t) => params.append('q', t));
    params.append('target', target);
    if (source) params.append('source', source);
    params.append('format', 'text');

    const body = params.toString();
    const options = {
      hostname: 'translation.googleapis.com',
      path: '/language/translate/v2',
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(body),
      },
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (res.statusCode !== 200) {
            reject(new Error(parsed.error?.message || 'Translation failed'));
            return;
          }
          const translations = parsed.data.translations.map((t) => t.translatedText);
          resolve(translations);
        } catch (e) {
          reject(e);
        }
      });
    });

    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

async function translateTexts(texts, target, source = 'en') {
  const clean = texts.map((t) => (t == null ? '' : String(t)));
  if (clean.length === 0) return [];

  if (target === source || target === 'en' && source === 'en') {
    return clean;
  }

  if (!isConfigured()) {
    return clean;
  }

  return translateRequest(clean, target, source);
}

async function translateText(text, target, source = 'en') {
  const [result] = await translateTexts([text], target, source);
  return result;
}

module.exports = { isConfigured, translateTexts, translateText };
