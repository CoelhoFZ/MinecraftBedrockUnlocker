const MAX_BODY = 16 * 1024;
const MAX_STR = 1000;
const ALLOWED_LANGS = new Set(['en', 'zh', 'hi', 'es', 'fr', 'ar', 'ru', 'pt']);

function clean(value, max) {
  if (typeof value !== 'string') return '';
  return value.slice(0, max)
    .replace(/[`<>\\]/g, '')
    .replace(/[\x00-\x1F\x7F]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method !== 'POST' || url.pathname !== '/report') {
      return new Response('Not Found', { status: 404 });
    }
    const contentLength = Number(request.headers.get('Content-Length') || 0);
    if (contentLength && contentLength > MAX_BODY) {
      return new Response('Payload Too Large', { status: 413 });
    }

    let payload;
    try {
      const raw = await request.text();
      if (raw.length > MAX_BODY) return new Response('Payload Too Large', { status: 413 });
      payload = JSON.parse(raw);
    } catch {
      return new Response('Bad Request', { status: 400 });
    }

    if (!payload || typeof payload !== 'object' || Array.isArray(payload) ||
        typeof payload.v !== 'string' || typeof payload.os !== 'string' ||
        typeof payload.lang !== 'string' || typeof payload.err !== 'string' ||
        typeof payload.smartScreen !== 'boolean') {
      return new Response('Bad Request', { status: 400 });
    }

    const version = clean(payload.v, 32);
    const os = clean(payload.os, 128);
    const lang = clean(payload.lang, 8);
    const error = clean(payload.err, MAX_STR);
    if (!version || !error) return new Response('Bad Request', { status: 400 });
    if (!env.DISCORD_WEBHOOK_URL) return new Response('Accepted', { status: 202 });

    const content = [
      '**MBU bootstrap error**',
      `version: \`${version}\``,
      `lang: \`${ALLOWED_LANGS.has(lang) ? lang : 'other'}\``,
      `os: \`${os}\``,
      `smartScreen: \`${payload.smartScreen ? 'yes' : 'no'}\``,
      `error: ${error}`,
    ].join('\n');

    try {
      await fetch(env.DISCORD_WEBHOOK_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content }),
      });
    } catch {
      // Reporting must never block or fail the bootstrap.
    }
    return new Response('Accepted', { status: 202 });
  },
};
