# Anx Reader CloudBase Reading Sync

This HTTP Function stores one replaceable Reading Agent package per
`sync-space / book / device`. It does not store books or the full Anx Reader
database. Merge semantics remain in the Flutter app.

## Runtime

- HTTP Function, Node.js 18 (`Nodejs18.15`)
- listen port: `9000`
- entrypoint: executable `scf_bootstrap`
- required environment variables:
  - `TCB_ENV`: the CloudBase environment ID
  - `CLOUDBASE_APIKEY`: a server-side API Key with access to CloudBase PG

Never put `CLOUDBASE_APIKEY` in Flutter, a gateway route, Git, logs, or an API
response. The function deliberately never echoes request headers, environment
variables, or CloudBase context.

## Self-hosting setup

1. Create a CloudBase environment with PostgreSQL enabled.
2. Apply every SQL file under `cloudbase/migrations/` in filename order.
3. Create a server API Key that can access CloudBase PostgreSQL.
4. Deploy this directory as a Node.js 18 HTTP Function using `scf_bootstrap`.
5. Set `TCB_ENV` and `CLOUDBASE_APIKEY` on the function. Never put the API Key
   in Flutter, Git, gateway parameters, logs, or an API response.
6. Bind a public HTTP gateway route to the function and enable rate limiting.
7. In Anx Reader, open Settings -> Sync -> CloudBase Reading Sync, enter the
   complete gateway URL, and register an account.
8. On another device, enter the same URL and sign in with the same account.

The username/password accounts described here belong to Anx Reader and are
stored in the private PostgreSQL tables below. They are not CloudBase Auth
users and do not call `/auth/v1/signup`.

## Database schema

The final schema after all migrations is:

### `anx_sync_spaces`

| Field | Type | Constraint |
| --- | --- | --- |
| `space_id_hash` | `varchar(64)` | primary key |
| `created_at` | `bigint` | not null |
| `updated_at` | `bigint` | not null |

### `anx_sync_accounts`

| Field | Type | Constraint |
| --- | --- | --- |
| `account_id` | `varchar(64)` | primary key |
| `username` | `varchar(48)` | unique, not null |
| `password_salt` | `varchar(64)` | not null |
| `password_hash` | `varchar(128)` | not null |
| `space_id_hash` | `varchar(64)` | not null, references `anx_sync_spaces` |
| `created_at` | `bigint` | not null |
| `updated_at` | `bigint` | not null |

### `anx_sync_sessions`

| Field | Type | Constraint |
| --- | --- | --- |
| `session_hash` | `varchar(64)` | primary key |
| `account_id` | `varchar(64)` | not null, references `anx_sync_accounts` with cascade delete |
| `expires_at` | `bigint` | not null |
| `created_at` | `bigint` | not null |

### `anx_sync_packages`

| Field | Type | Constraint |
| --- | --- | --- |
| `package_id` | `varchar(64)` | primary key |
| `space_id_hash` | `varchar(64)` | not null, references `anx_sync_spaces` with cascade delete |
| `book_key` | `varchar(160)` | not null |
| `device_id` | `varchar(160)` | not null |
| `generated_at` | `bigint` | not null |
| `payload` | `jsonb` | not null |
| `updated_at` | `bigint` | not null |

`anx_sync_packages` has a unique constraint on
`(space_id_hash, book_key, device_id)`. The migrations also create
`anx_sync_packages_book_idx`, `anx_sync_sessions_account_idx`, and the unique
username index provided by the account constraint.

All four tables revoke access from `anon` and `authenticated`, grant required
CRUD access to `service_role`, and enable RLS without client-facing policies.
All database access must go through the HTTP Function.

## HTTP API

- `GET /health`
- `POST /v1/account/register` with `{ "username": "reader", "password": "..." }`
- `POST /v1/account/login` with `{ "username": "reader", "password": "..." }`
- `POST /v1/account/logout`
- `GET /v1/spaces/current`
- `GET /v1/books/:bookKey/packages`
- `PUT /v1/books/:bookKey/packages/:deviceId`

Registration automatically creates the account's private sync space. No
invitation is required; additional devices use the same account credentials.

All sync routes except health and account registration/login require:

```text
Authorization: Bearer <accountSession>
```

The database stores only a SHA-256 hash of the session and uses scrypt for
password hashes. Space IDs and recovery codes are not accepted. Limit the
public gateway route to this function and monitor account/package writes.
Package request bodies are capped at 2 MiB.
