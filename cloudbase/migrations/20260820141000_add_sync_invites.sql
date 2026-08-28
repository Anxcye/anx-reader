CREATE TABLE public.anx_sync_invites (
  invite_hash varchar(64) PRIMARY KEY,
  created_at bigint NOT NULL,
  expires_at bigint,
  used_at bigint,
  used_by_space_hash varchar(64)
);

REVOKE ALL ON public.anx_sync_invites FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.anx_sync_invites TO service_role;
ALTER TABLE public.anx_sync_invites ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.anx_sync_spaces
  ADD COLUMN invite_hash varchar(64)
  REFERENCES public.anx_sync_invites(invite_hash);

CREATE UNIQUE INDEX anx_sync_spaces_invite_idx
  ON public.anx_sync_spaces (invite_hash)
  WHERE invite_hash IS NOT NULL;

CREATE FUNCTION public.consume_anx_sync_invite()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.invite_hash IS NULL THEN
    RAISE EXCEPTION 'invalid_invitation';
  END IF;

  UPDATE public.anx_sync_invites
  SET used_at = NEW.created_at,
      used_by_space_hash = NEW.space_id_hash
  WHERE invite_hash = NEW.invite_hash
    AND used_at IS NULL
    AND (expires_at IS NULL OR expires_at > NEW.created_at);

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_invitation';
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.consume_anx_sync_invite() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.consume_anx_sync_invite() TO service_role;

CREATE TRIGGER anx_sync_space_consume_invite
BEFORE INSERT ON public.anx_sync_spaces
FOR EACH ROW
EXECUTE FUNCTION public.consume_anx_sync_invite();
