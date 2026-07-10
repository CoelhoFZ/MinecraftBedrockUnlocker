// Cloudflare Worker - Badge JSON para CoelhoFZ/MinecraftBedrockUnlocker
// Hardening: CORS restrito + rate limit opcional via KV
// URL: https://minecraft-bedrock-badge.xgobg2020.workers.dev/downloads.json

const ALLOWED_ORIGINS = new Set([
    'https://img.shields.io',
    'https://cdn.jsdelivr.net',
    'https://github.com',
]);

// Rate limit opcional: so funciona se voce criar um KV namespace chamado
// RATE_LIMIT_KV nas Settings do Worker. Sem KV, a funcao retorna true
// (libera) e o badge funciona normal.
const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX = 60;

export default {
    async fetch(request, env, ctx) {
        const url = new URL(request.url);

        if (request.method === 'OPTIONS') {
            return new Response(null, {
                status: 204,
                headers: corsHeaders(request),
            });
        }

        if (url.pathname !== '/downloads.json') {
            return new Response('Not found', { status: 404 });
        }

        const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
        const allowed = await checkRateLimit(env, ip);
        if (!allowed) {
            return new Response(JSON.stringify({ error: 'rate_limited' }), {
                status: 429,
                headers: {
                    'Content-Type': 'application/json',
                    'Retry-After': '60',
                    ...corsHeaders(request),
                },
            });
        }

        const cache = caches.default;
        const cached = await cache.match(request);
        if (cached) {
            return new Response(await cached.clone().text(), {
                status: 200,
                headers: {
                    ...Object.fromEntries(cached.headers.entries()),
                    ...corsHeaders(request),
                },
            });
        }

        const ghRes = await fetch(
            'https://api.github.com/repos/CoelhoFZ/MinecraftBedrockUnlocker/releases?per_page=100',
            {
                headers: {
                    Authorization: `Bearer ${env.GITHUB_PAT}`,
                    Accept: 'application/vnd.github+json',
                    'User-Agent': 'minecraft-bedrock-badge-worker',
                },
            }
        );

        if (!ghRes.ok) {
            return new Response(JSON.stringify({ error: 'github_api_error', status: ghRes.status }), {
                status: 502,
                headers: { 'Content-Type': 'application/json', ...corsHeaders(request) },
            });
        }

        const releases = await ghRes.json();
        const total = releases.reduce(
            (sum, r) => sum + (r.assets || []).reduce((a, asset) => a + (asset.download_count || 0), 0),
            0
        );

        const body = JSON.stringify({
            schemaVersion: 1,
            label: 'Downloads',
            message: total >= 1000 ? `${(total / 1000).toFixed(1)}k` : String(total),
            color: 'blue',
            namedLogo: 'windows',
        });

        const responseHeaders = {
            'Content-Type': 'application/json',
            'Cache-Control': 'public, max-age=3600, s-maxage=3600',
            ...corsHeaders(request),
        };

        const response = new Response(body, { status: 200, headers: responseHeaders });

        ctx.waitUntil(
            cache.put(
                request,
                new Response(body, {
                    status: 200,
                    headers: {
                        'Content-Type': 'application/json',
                        'Cache-Control': 'public, max-age=3600, s-maxage=3600',
                    },
                })
            )
        );

        return response;
    },
};

function corsHeaders(request) {
    const origin = request.headers.get('Origin') || '';
    const allowedOrigin = ALLOWED_ORIGINS.has(origin) ? origin : '';
    return {
        'Access-Control-Allow-Origin': allowedOrigin,
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Max-Age': '86400',
        'X-Content-Type-Options': 'nosniff',
    };
}

async function checkRateLimit(env, ip) {
    if (!env.RATE_LIMIT_KV) return true;

    const key = `rate:${ip}`;
    const now = Date.now();
    const data = (await env.RATE_LIMIT_KV.get(key, 'json')) || { count: 0, resetAt: now + RATE_LIMIT_WINDOW_MS };

    if (now > data.resetAt) {
        data.count = 0;
        data.resetAt = now + RATE_LIMIT_WINDOW_MS;
    }

    data.count += 1;
    await env.RATE_LIMIT_KV.put(key, JSON.stringify(data), { expirationTtl: 120 });

    return data.count <= RATE_LIMIT_MAX;
}
