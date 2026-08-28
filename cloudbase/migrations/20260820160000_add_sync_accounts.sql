DROP TRIGGER IF EXISTS anx_sync_space_consume_invite ON public.anx_sync_spaces;
DROP FUNCTION IF EXISTS public.consume_anx_sync_invite();
DROP INDEX IF EXISTS public.anx_sync_spaces_invite_idx;
ALTER TABLE public.anx_sync_spaces DROP COLUMN IF EXISTS invite_hash;
DROP TABLE IF EXISTS public.anx_sync_invites;

CREATE TABLE public.anx_sync_accounts (
  account_id varchar(64) PRIMARY KEY,
  username varchar(48) NOT NULL UNIQUE,
  password_salt varchar(64) NOT NULL,
  password_hash varchar(128) NOT NULL,
  space_id_hash varchar(64) NOT NULL REFERENCES public.anx_sync_spaces(space_id_hash) ON DELETE CASCADE,
  created_at bigint NOT NULL,
  updated_at bigint NOT NULL
);

CREATE TABLE public.anx_sync_sessions (
  session_hash varchar(64) PRIMARY KEY,
  account_id varchar(64) NOT NULL REFERENCES public.anx_sync_accounts(account_id) ON DELETE CASCADE,
  expires_at bigint NOT NULL,
  created_at bigint NOT NULL
);

CREATE INDEX anx_sync_sessions_account_idx
  ON public.anx_sync_sessions (account_id, expires_at);

REVOKE ALL ON public.anx_sync_accounts FROM anon, authenticated;
REVOKE ALL ON public.anx_sync_sessions FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.anx_sync_accounts TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.anx_sync_sessions TO service_role;

ALTER TABLE public.anx_sync_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.anx_sync_sessions ENABLE ROW LEVEL SECURITY;
