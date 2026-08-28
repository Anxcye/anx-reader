'use strict';

const assert = require('node:assert/strict');
const http = require('node:http');
const test = require('node:test');
const { createHandler } = require('../index');

function memoryRepository() {
  const spaces = new Map();
  const packages = new Map();
  const accounts = new Map();
  const sessions = new Map();
  return {
    spaces,
    async createSpace(row) {
      spaces.set(row.space_id_hash, row);
    },
    async createAccount(row) { accounts.set(row.username, row); },
    async getAccountByUsername(username) { return accounts.get(username) || null; },
    async getAccount(id) { return [...accounts.values()].find((v) => v.account_id === id) || null; },
    async createSession(row) { sessions.set(row.session_hash, row); },
    async getSession(hash, now) {
      const row = sessions.get(hash);
      return row && row.expires_at > now ? row : null;
    },
    async deleteSession(hash) { sessions.delete(hash); },
    async listPackages(space, book) {
      return [...packages.values()]
        .filter((row) => row.space_id_hash === space && row.book_key === book)
        .map((row) => row.payload);
    },
    async putPackage(row) { packages.set(row.package_id, row); },
  };
}

async function withServer(run) {
  const repository = memoryRepository();
  const server = http.createServer(createHandler(repository));
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  try {
    await run(`http://127.0.0.1:${server.address().port}`, repository);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

test('health does not expose runtime data', () => withServer(async (base) => {
  const response = await fetch(`${base}/health`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { ok: true });
}));

test('one account can use the same sync space from multiple logins', () => withServer(async (base) => {
  const created = await fetch(`${base}/v1/account/register`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'reader', password: 'reader-pass-123' }),
  });
  assert.equal(created.status, 201);
  const first = await created.json();
  const loggedIn = await fetch(`${base}/v1/account/login`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'reader', password: 'reader-pass-123' }),
  });
  assert.equal(loggedIn.status, 200);
  const second = await loggedIn.json();
  const headers = {
    Authorization: `Bearer ${first.accessToken}`,
    'Content-Type': 'application/json',
  };
  const payload = {
    type: 'anx-reading-agent-book-delta', schemaVersion: 1,
    bookKey: 'book-a', deviceId: 'device-a', generatedAt: 1, rows: {},
  };
  const put = await fetch(`${base}/v1/books/book-a/packages/device-a`, {
    method: 'PUT', headers, body: JSON.stringify(payload),
  });
  assert.equal(put.status, 204);
  const get = await fetch(`${base}/v1/books/book-a/packages`, {
    headers: { ...headers, Authorization: `Bearer ${second.accessToken}` },
  });
  assert.deepEqual((await get.json()).packages, [payload]);

  const denied = await fetch(`${base}/v1/books/book-a/packages`, {
    headers: { ...headers, Authorization: 'Bearer wrong' },
  });
  assert.equal(denied.status, 401);
}));

test('registration needs no invitation and rejects duplicate account', () =>
  withServer(async (base) => {
    const create = () => fetch(`${base}/v1/account/register`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username: 'reader2', password: 'reader-pass-123' }),
    });
    assert.equal((await create()).status, 201);
    assert.equal((await create()).status, 409);
    const wrong = await fetch(`${base}/v1/account/login`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username: 'reader2', password: 'wrong-pass-999' }),
    });
    assert.equal(wrong.status, 401);
  }));

test('rejects a package whose path and payload identities differ', () =>
  withServer(async (base, repository) => {
    const created = await fetch(`${base}/v1/account/register`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username: 'reader3', password: 'reader-pass-123' }),
    });
    const session = await created.json();
    const response = await fetch(`${base}/v1/books/book-a/packages/device-a`, {
      method: 'PUT',
      headers: {
        Authorization: `Bearer ${session.accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        type: 'anx-reading-agent-book-delta', schemaVersion: 1,
        bookKey: 'book-b', deviceId: 'device-a', generatedAt: 1, rows: {},
      }),
    });
    assert.equal(response.status, 400);
  }));

test('rejects removed legacy space credentials', () =>
  withServer(async (base) => {
    const response = await fetch(`${base}/v1/spaces/current`, {
      headers: {
        Authorization: 'Bearer legacy-recovery-code',
        'X-Anx-Sync-Space': 'legacy-space-id',
      },
    });
    assert.equal(response.status, 401);
  }));
