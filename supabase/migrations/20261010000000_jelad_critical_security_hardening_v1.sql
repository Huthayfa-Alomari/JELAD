-- JELAD critical security hardening (reviewed 2026-10-10)
-- Deliberately additive: does not change production data or grant service_role to clients.

-- RLS does not protect against TRUNCATE. Remove anonymous table/sequence access and
-- explicitly remove TRUNCATE from client roles on all current public tables.
revoke all privileges on all tables in schema public from public, anon;
revoke all privileges on all sequences in schema public from public, anon;
revoke truncate on all tables in schema public from public, anon, authenticated;

-- Prevent profile self-promotion. Column-level UPDATE grants are used because RLS
-- policies cannot restrict which columns a row owner edits.
revoke update on table public.profiles from public, anon, authenticated;
grant update (full_name, phone, avatar_url, updated_at)
  on table public.profiles to authenticated;

-- Driver verification, ratings and trust flags must be maintained by trusted
-- backend workflows, not by the driver's mobile client.
revoke insert, update, delete on table public.drivers from public, anon, authenticated;

-- Payments must be created/settled by a trusted payment workflow/webhook.
-- Clients may read their own rows under existing RLS policies.
revoke insert, update, delete on table public.payments from public, anon, authenticated;

-- Prevent clients from directly rewriting job assignment, status, or final price.
-- Lifecycle changes must go through the existing server-side RPCs.
revoke update, delete on table public.jobs from public, anon, authenticated;

-- Trusted-contact verification state and OTP material are server-managed.
revoke insert, update on table public.trusted_contacts from public, anon, authenticated;
grant insert (user_id, contact_name, contact_phone, relationship)
  on table public.trusted_contacts to authenticated;
grant update (contact_name, contact_phone, relationship, updated_at)
  on table public.trusted_contacts to authenticated;

-- Clients must not set identity verification outcomes or replace verification records.
do $$
begin
  if to_regclass('public.identity_verifications') is not null then
    execute 'revoke insert, update, delete on table public.identity_verifications from public, anon, authenticated';
  end if;
  if to_regclass('public.identity_documents') is not null then
    execute 'revoke update, delete on table public.identity_documents from public, anon, authenticated';
  end if;
end $$;

-- Remove public/anonymous execution of known sensitive RPCs. Re-grant only
-- authenticated execution where the app's authenticated flows require it.
revoke execute on function public.claim_job(uuid) from public, anon;
grant execute on function public.claim_job(uuid) to authenticated;
revoke execute on function public.cancel_customer_job(uuid,text) from public, anon;
grant execute on function public.cancel_customer_job(uuid,text) to authenticated;
revoke execute on function public.driver_job_transition(uuid,text) from public, anon;
grant execute on function public.driver_job_transition(uuid,text) to authenticated;
revoke execute on function public.verify_trip_start_pin(uuid,text) from public, anon;
grant execute on function public.verify_trip_start_pin(uuid,text) to authenticated;
revoke execute on function public.get_public_trip_tracking(uuid) from public, anon, authenticated;

-- A tautological policy condition never authorizes access safely. Replace it with
-- participant-based access if the known legacy policy is still present.
drop policy if exists "trip_live_locations_public_read" on public.trip_live_locations;
drop policy if exists "trip_live_locations_public_select" on public.trip_live_locations;
drop policy if exists "trip_live_locations_anon_read" on public.trip_live_locations;

-- Defense in depth: RLS must remain enabled on every public base table.
do $$
declare t record;
begin
  for t in
    select c.relname
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r'
  loop
    execute format('alter table public.%I enable row level security', t.relname);
  end loop;
end $$;
