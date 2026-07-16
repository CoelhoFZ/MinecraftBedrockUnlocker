const MAX_BODY = 16 * 1024;
const MAX_STR = 1000;
const ALLOWED_LANGS = new Set(['en', 'zh', 'hi', 'es', 'fr', 'ar', 'ru', 'pt']);

// Simple in-memory rate limiting (per isolate)
const ipRequests = new Map();
const RATE_LIMIT = 5; 
const WINDOW_MS = 60 * 1000;

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

    // Rate limiting
    const ip = request.headers.get('CF-Connecting-IP') || 'anonymous';
    const now = Date.now();
    const record = ipRequests.get(ip) || { count: 0, startTime: now };

    if (now - record.startTime > WINDOW_MS) {
      record.count = 1;
      record.startTime = now;
    } else {
      record.count++;
    }
    
    // Simple cleanup to prevent memory leak
    if (ipRequests.size > 1000) {
      for (const [key, val] of ipRequests) {
        if (now - val.startTime > WINDOW_MS) ipRequests.delete(key);
      }
    }
    
    ipRequests.set(ip, record);

    if (record.count > RATE_LIMIT) {
      return new Response('Too Many Requests', { status: 429 });
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
    const mcStatus = clean(payload.mc, 128);
    const hw = payload.hw || {};
    
    if (!version || !error) return new Response('Bad Request', { status: 400 });
    if (!env.DISCORD_WEBHOOK_URL) return new Response('Accepted', { status: 202 });

    const content = [
      '**🚨 MBU Bootstrap Error**',
      `> **Version:** \`${version}\` | **Lang:** \`${ALLOWED_LANGS.has(lang) ? lang : 'other'}\``,
      `> **OS:** \`${os}\` (\`${clean(hw.arch, 16)}\`)`,
      `> **CPU:** \`${clean(hw.cpu, 128)}\``,
      `> **GPU:** \`${clean(hw.gpu, 128)}\``,
      `> **Board:** \`${clean(hw.board, 128)}\``,
      `> **Minecraft:** \`${mcStatus}\``,
      `> **SmartScreen:** \`${payload.smartScreen ? 'Yes' : 'No'}\``,
      '',
      '**Error Message:**',
      `\`\`\`\n${error}\n\`\`\``,
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
