'use strict';

const crypto = require('node:crypto');
const http = require('node:http');

const MAX_BODY_BYTES = 2 * 1024 * 1024;
const MAX_PACKAGES_PER_BOOK = 100;
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, OPTIONS',
  'Access-Control-Allow-Headers':
    'Authorization, Content-Type, X-Device-Id',
};

function sha256(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function randomSecret(bytes) {
  return crypto.randomBytes(bytes).toString('base64url');
}

function hashPassword(password, salt) {
  return new Promise((resolve, reject) => {
    crypto.scrypt(password, salt, 64, { N: 16384, r: 8, p: 1 }, (error, key) => {
      if (error) reject(error);
      else resolve(key.toString('hex'));
    });
  });
}

function validUsername(value) {
  return typeof value === 'string' && /^[A-Za-z0-9][A-Za-z0-9._-]{1,47}$/.test(value);
}

function validPassword(value) {
  return typeof value === 'string' && value.length >= 8 && value.length <= 128;
}

function createPgRepository({ envId, apiKey, fetchImpl = fetch }) {
  if (!envId || !apiKey) throw new Error('TCB_ENV and CLOUDBASE_APIKEY are required');
  const base = `https://${envId}.api.tcloudbasegateway.com/v1/rdb/rest`;

  async function request(table, { method = 'GET', query = '', body, prefer } = {}) {
    const response = await fetchImpl(`${base}/${table}${query}`, {
      method,
      headers: {
        Authorization: `Bearer ${apiKey}`,
        Accept: 'application/json',
        'Content-Type': 'application/json',
        ...(prefer ? { Prefer: prefer } : {}),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    if (!response.ok) {
      const detail = await response.text();
      throw new Error(`CloudBase PG request failed (${response.status}): ${detail.slice(0, 300)}`);
    }
    if (response.status === 204) return null;
    const text = await response.text();
    return text ? JSON.parse(text) : null;
  }

  return {
    async createSpace(space) {
      await request('anx_sync_spaces', { method: 'POST', body: space });
    },
    async createAccount(account) {
      await request('anx_sync_accounts', { method: 'POST', body: account });
    },
    async getAccountByUsername(username) {
      const rows = await request('anx_sync_accounts', {
        query: `?select=account_id,username,password_salt,password_hash,space_id_hash&username=eq.${encodeURIComponent(username)}&limit=1`,
      });
      return Array.isArray(rows) ? rows[0] || null : null;
    },
    async createSession(session) {
      await request('anx_sync_sessions', { method: 'POST', body: session });
    },
    async getSession(sessionHash, now) {
      const rows = await request('anx_sync_sessions', {
        query: `?select=account_id,expires_at&session_hash=eq.${encodeURIComponent(sessionHash)}&expires_at=gt.${now}&limit=1`,
      });
      return Array.isArray(rows) ? rows[0] || null : null;
    },
    async deleteSession(sessionHash) {
      await request('anx_sync_sessions', {
        method: 'DELETE',
        query: `?session_hash=eq.${encodeURIComponent(sessionHash)}`,
      });
    },
    async getAccount(accountId) {
      const rows = await request('anx_sync_accounts', {
        query: `?select=account_id,username,space_id_hash&account_id=eq.${encodeURIComponent(accountId)}&limit=1`,
      });
      return Array.isArray(rows) ? rows[0] || null : null;
    },
    async listPackages(spaceIdHash, bookKey) {
      const rows = await request('anx_sync_packages', {
        query: `?select=payload&space_id_hash=eq.${encodeURIComponent(spaceIdHash)}` +
          `&book_key=eq.${encodeURIComponent(bookKey)}` +
          `&order=updated_at.desc&limit=${MAX_PACKAGES_PER_BOOK}`,
      });
      return (Array.isArray(rows) ? rows : []).map((row) => row.payload);
    },
    async putPackage(record) {
      await request('anx_sync_packages', {
        method: 'POST',
        body: record,
        prefer: 'resolution=merge-duplicates,return=minimal',
      });
    },
  };
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    req.on('data', (chunk) => {
      size += chunk.length;
      if (size > MAX_BODY_BYTES) {
        reject(Object.assign(new Error('Request body is too large'), { statusCode: 413 }));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => {
      if (!chunks.length) return resolve({});
      try {
        resolve(JSON.parse(Buffer.concat(chunks).toString('utf8')));
      } catch (_) {
        reject(Object.assign(new Error('Invalid JSON'), { statusCode: 400 }));
      }
    });
    req.on('error', reject);
  });
}

function send(res, status, body) {
  if (status === 204) {
    res.writeHead(status, { 'Cache-Control': 'no-store', ...CORS_HEADERS });
    res.end();
    return;
  }
  const encoded = JSON.stringify(body);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    ...CORS_HEADERS,
    'Content-Length': Buffer.byteLength(encoded),
  });
  res.end(encoded);
}

function validSegment(value, max = 160) {
  return typeof value === 'string' && value.length > 0 && value.length <= max &&
    /^[a-zA-Z0-9._-]+$/.test(value);
}

function validatePackage(payload, bookKey, deviceId) {
  return payload && payload.type === 'anx-reading-agent-book-delta' &&
    payload.schemaVersion === 1 && payload.bookKey === bookKey &&
    payload.deviceId === deviceId && Number.isInteger(payload.generatedAt) &&
    payload.rows && typeof payload.rows === 'object' && !Array.isArray(payload.rows);
}

function bearerToken(req) {
  const value = req.headers.authorization || '';
  return value.startsWith('Bearer ') ? value.slice(7) : '';
}

function createHandler(repository) {
  return async function handler(req, res) {
    try {
      const url = new URL(req.url, 'http://localhost');
      if (req.method === 'OPTIONS') return send(res, 204, {});
      if (req.method === 'GET' && url.pathname === '/health') {
        return send(res, 200, { ok: true });
      }
      if (req.method === 'POST' && url.pathname === '/v1/account/register') {
        const body = await readBody(req);
        const username = typeof body.username === 'string' ? body.username.trim() : '';
        const password = body.password;
        if (!validUsername(username) || !validPassword(password)) {
          return send(res, 400, { error: 'invalid_credentials' });
        }
        const existing = await repository.getAccountByUsername(username);
        if (existing) return send(res, 409, { error: 'account_unavailable' });
        const now = Date.now();
        const accountId = randomSecret(24);
        const spaceId = randomSecret(16);
        const salt = randomSecret(16);
        const passwordHash = await hashPassword(password, salt);
        const space = {
          space_id_hash: sha256(spaceId),
          created_at: now, updated_at: now,
        };
        await repository.createSpace(space);
        try {
          await repository.createAccount({
            account_id: accountId, username, password_salt: salt,
            password_hash: passwordHash, space_id_hash: space.space_id_hash,
            created_at: now, updated_at: now,
          });
        } catch (error) {
          // The space is harmless without an account and remains inaccessible.
          throw error;
        }
        const session = randomSecret(32);
        await repository.createSession({
          session_hash: sha256(session), account_id: accountId,
          expires_at: now + 30 * 24 * 60 * 60 * 1000, created_at: now,
        });
        return send(res, 201, { username, accessToken: session, expiresIn: 30 * 24 * 60 * 60 });
      }
      if (req.method === 'POST' && url.pathname === '/v1/account/login') {
        const body = await readBody(req);
        const username = typeof body.username === 'string' ? body.username.trim() : '';
        const password = body.password;
        if (!validUsername(username) || !validPassword(password)) {
          return send(res, 401, { error: 'invalid_credentials' });
        }
        const account = await repository.getAccountByUsername(username);
        if (!account) return send(res, 401, { error: 'invalid_credentials' });
        const passwordHash = await hashPassword(password, account.password_salt);
        const left = Buffer.from(passwordHash, 'hex');
        const right = Buffer.from(account.password_hash || '', 'hex');
        if (left.length !== right.length || !crypto.timingSafeEqual(left, right)) {
          return send(res, 401, { error: 'invalid_credentials' });
        }
        const session = randomSecret(32);
        const now = Date.now();
        await repository.createSession({
          session_hash: sha256(session), account_id: account.account_id,
          expires_at: now + 30 * 24 * 60 * 60 * 1000, created_at: now,
        });
        return send(res, 200, { username, accessToken: session, expiresIn: 30 * 24 * 60 * 60 });
      }

      if (req.method === 'POST' && url.pathname === '/v1/account/logout') {
        const token = bearerToken(req);
        if (token) await repository.deleteSession(sha256(token));
        return send(res, 204, {});
      }
      const token = bearerToken(req);
      if (!token) return send(res, 401, { error: 'unauthorized' });
      const session = await repository.getSession(sha256(token), Date.now());
      const account = session ? await repository.getAccount(session.account_id) : null;
      const spaceIdHash = account?.space_id_hash || '';
      if (!spaceIdHash) return send(res, 401, { error: 'unauthorized' });

      if (req.method === 'GET' && url.pathname === '/v1/spaces/current') {
        return send(res, 200, { ok: true });
      }

      const getMatch = url.pathname.match(/^\/v1\/books\/([^/]+)\/packages$/);
      if (req.method === 'GET' && getMatch) {
        const bookKey = decodeURIComponent(getMatch[1]);
        if (!validSegment(bookKey)) return send(res, 400, { error: 'invalid_book_key' });
        const packages = await repository.listPackages(spaceIdHash, bookKey);
        return send(res, 200, { packages });
      }

      const putMatch = url.pathname.match(/^\/v1\/books\/([^/]+)\/packages\/([^/]+)$/);
      if (req.method === 'PUT' && putMatch) {
        const bookKey = decodeURIComponent(putMatch[1]);
        const deviceId = decodeURIComponent(putMatch[2]);
        if (!validSegment(bookKey) || !validSegment(deviceId)) {
          return send(res, 400, { error: 'invalid_path' });
        }
        const payload = await readBody(req);
        if (!validatePackage(payload, bookKey, deviceId)) {
          return send(res, 400, { error: 'invalid_package' });
        }
        await repository.putPackage({
          package_id: sha256(`${spaceIdHash}:${bookKey}:${deviceId}`),
          space_id_hash: spaceIdHash,
          book_key: bookKey,
          device_id: deviceId,
          generated_at: payload.generatedAt,
          payload,
          updated_at: Date.now(),
        });
        return send(res, 204, {});
      }
      return send(res, 404, { error: 'not_found' });
    } catch (error) {
      return send(res, error.statusCode || 500, {
        error: error.statusCode ? error.message : 'internal_error',
      });
    }
  };
}

function start() {
  const repository = createPgRepository({
    envId: process.env.TCB_ENV,
    apiKey: process.env.CLOUDBASE_APIKEY,
  });
  return http.createServer(createHandler(repository)).listen(9000, '0.0.0.0');
}

if (require.main === module) start();

module.exports = {
  createHandler,
  createPgRepository,
  hashPassword,
  sha256,
  start,
};
