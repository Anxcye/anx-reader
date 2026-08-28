CREATE TABLE public.anx_sync_spaces (
  space_id_hash varchar(64) PRIMARY KEY,
  token_hash varchar(64) NOT NULL,
  created_at bigint NOT NULL,
  updated_at bigint NOT NULL
);

CREATE TABLE public.anx_sync_packages (
  package_id varchar(64) PRIMARY KEY,
  space_id_hash varchar(64) NOT NULL REFERENCES public.anx_sync_spaces(space_id_hash) ON DELETE CASCADE,
  book_key varchar(160) NOT NULL,
  device_id varchar(160) NOT NULL,
  generated_at bigint NOT NULL,
  payload jsonb NOT NULL,
  updated_at bigint NOT NULL,
  UNIQUE (space_id_hash, book_key, device_id)
);

CREATE INDEX anx_sync_packages_book_idx
  ON public.anx_sync_packages (space_id_hash, book_key, updated_at DESC);

REVOKE ALL ON public.anx_sync_spaces FROM anon, authenticated;
REVOKE ALL ON public.anx_sync_packages FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.anx_sync_spaces TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.anx_sync_packages TO service_role;

ALTER TABLE public.anx_sync_spaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.anx_sync_packages ENABLE ROW LEVEL SECURITY;

-- No client-facing policies are intentional. Only the HTTP function's
-- service_role credential may access these tables.
