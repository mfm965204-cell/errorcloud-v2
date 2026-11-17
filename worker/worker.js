/**
 * Errorcloud — blind storage backend (Cloudflare Worker)
 *
 * The server never sees a key and never sees plaintext. It only stores opaque
 * encrypted blobs under short random IDs.
 *
 *   POST /upload          raw binary body  -> { "id": "X7F9A2C" }
 *   GET  /download/:id    -> application/octet-stream
 *   GET  /health          -> { ok, storage }
 *
 * Storage: R2 binding BUCKET if present, otherwise KV binding VAULT_KV.
 * Developed by Error
 */

const ID_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const ID_LENGTH = 6;
const MAX_BYTES = 20 * 1024 * 1024;

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Max-Age': '86400',
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json; charset=utf-8' },
  });
}

function newId() {
  const bytes = crypto.getRandomValues(new Uint8Array(ID_LENGTH));
  let out = '';
  for (let i = 0; i < ID_LENGTH; i++) out += ID_ALPHABET[bytes[i] % ID_ALPHABET.length];
  return out;
}

function storage(env) {
  if (env.BUCKET) {
    return {
      kind: 'r2',
      async put(key, buf) {
        await env.BUCKET.put(key, buf);
      },
      async get(key) {
        const obj = await env.BUCKET.get(key);
        return obj ? await obj.arrayBuffer() : null;
      },
      async exists(key) {
        return (await env.BUCKET.head(key)) !== null;
      },
    };
  }
  if (env.VAULT_KV) {
    return {
      kind: 'kv',
      async put(key, buf) {
        await env.VAULT_KV.put(key, buf);
      },
      async get(key) {
        return (await env.VAULT_KV.get(key, 'arrayBuffer')) || null;
      },
      async exists(key) {
        return (await env.VAULT_KV.get(key, 'arrayBuffer')) !== null;
      },
    };
  }
  return null;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS });
    }

    const store = storage(env);

    if (url.pathname === '/health') {
      return json({ ok: true, service: 'errorcloud-api', storage: store ? store.kind : 'unconfigured' });
    }

    if (url.pathname === '/upload') {
      if (request.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);
      if (!store) return json({ error: 'storage_unconfigured' }, 503);

      const buf = await request.arrayBuffer();
      if (!buf || buf.byteLength === 0) return json({ error: 'empty_body' }, 400);
      if (buf.byteLength > MAX_BYTES) return json({ error: 'payload_too_large', max: MAX_BYTES }, 413);

      for (let attempt = 0; attempt < 5; attempt++) {
        const id = newId();
        if (await store.exists(id)) continue;
        await store.put(id, buf);
        return json({ id, size: buf.byteLength });
      }
      return json({ error: 'id_collision' }, 500);
    }

    const match = url.pathname.match(/^\/download\/([A-Z0-9]{6})$/);
    if (match) {
      if (request.method !== 'GET') return json({ error: 'method_not_allowed' }, 405);
      if (!store) return json({ error: 'storage_unconfigured' }, 503);

      const buf = await store.get(match[1]);
      if (!buf) return json({ error: 'not_found' }, 404);

      return new Response(buf, {
        status: 200,
        headers: {
          ...CORS,
          'Content-Type': 'application/octet-stream',
          'Content-Length': String(buf.byteLength),
          'Cache-Control': 'no-store',
          'X-Content-Type-Options': 'nosniff',
        },
      });
    }

    return json({ error: 'not_found', hint: 'POST /upload or GET /download/:id' }, 404);
  },
};
