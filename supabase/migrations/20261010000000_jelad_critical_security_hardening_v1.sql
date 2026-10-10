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

-- Prevent clients from directly creating or rewriting job assignment, status, or final price.
-- Creation and lifecycle changes must go through the server-side RPCs.
revoke insert, update, delete on table public.jobs from public, anon, authenticated;

-- The existing create_job RPC was SECURITY INVOKER and relied on direct table grants.
-- Make it a guarded SECURITY DEFINER endpoint so clients cannot forge status/driver/final fare.
create or replace function public.create_job(
  p_type public.job_type,
  p_pickup_address text,
  p_pickup_lat double precision,
  p_pickup_lng double precision,
  p_destination_address text,
  p_destination_lat double precision,
  p_destination_lng double precision,
  p_estimated_amount numeric default 0,
  p_notes text default null
) returns public.jobs
language plpgsql
security definer
set search_path = public, pg_temp
as $
declare
  v_job public.jobs;
  v_pickup uuid;
  v_destination uuid;
  v_quote jsonb;
  v_amount numeric;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if p_type is null or p_pickup_address is null or length(trim(p_pickup_address)) = 0
     or p_destination_address is null or length(trim(p_destination_address)) = 0 then
    raise exception 'job type and addresses are required';
  end if;
  if p_pickup_lat not between -90 and 90 or p_destination_lat not between -90 and 90
     or p_pickup_lng not between -180 and 180 or p_destination_lng not between -180 and 180 then
    raise exception 'invalid coordinates';
  end if;
  if abs(p_pickup_lat) < 0.000001 and abs(p_pickup_lng) < 0.000001 then raise exception 'pickup coordinates required'; end if;
  if abs(p_destination_lat) < 0.000001 and abs(p_destination_lng) < 0.000001 then raise exception 'destination coordinates required'; end if;
  if p_notes is not null and length(p_notes) > 2000 then raise exception 'notes too long'; end if;

  v_quote := public.quote_job_fare(p_type,p_pickup_lat,p_pickup_lng,p_destination_lat,p_destination_lng,null);
  -- Never trust a client-supplied amount as the authoritative fare.
  v_amount := (v_quote->>'amount')::numeric;

  insert into public.locations(owner_id,label,address,latitude,longitude)
  values(auth.uid(),'Pickup',left(trim(p_pickup_address),300),p_pickup_lat,p_pickup_lng)
  returning id into v_pickup;
  insert into public.locations(owner_id,label,address,latitude,longitude)
  values(auth.uid(),'Destination',left(trim(p_destination_address),300),p_destination_lat,p_destination_lng)
  returning id into v_destination;

  insert into public.jobs(customer_id,type,status,pickup_location_id,destination_location_id,estimated_amount,price_breakdown,notes)
  values(auth.uid(),p_type,'REQUESTED',v_pickup,v_destination,v_amount,v_quote,left(p_notes,2000))
  returning * into v_job;
  return v_job;
end;
$;
revoke all on function public.create_job(public.job_type,text,double precision,double precision,text,double precision,double precision,numeric,text) from public, anon;
grant execute on function public.create_job(public.job_type,text,double precision,double precision,text,double precision,double precision,numeric,text) to authenticated;

-- Repair the driver transition RPC: the live schema keys drivers by profile id and has no drivers.user_id.
create or replace function public.driver_job_transition(p_job_id uuid, p_action text)
returns public.jobs
language plpgsql
security definer
set search_path = public, pg_temp
as $
declare v_job public.jobs; v_driver public.drivers;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  select * into v_driver from public.drivers where id=auth.uid() for update;
  if v_driver.id is null then raise exception 'driver not found'; end if;
  select * into v_job from public.jobs where id=p_job_id and driver_id=v_driver.id for update;
  if v_job.id is null then raise exception 'job not assigned to driver'; end if;
  if p_action='ARRIVED' and v_job.status='ASSIGNED' then
    update public.jobs set status='DRIVER_ARRIVING',driver_arrived_at=now(),updated_at=now() where id=v_job.id returning * into v_job;
  elsif p_action='START' and v_job.status='DRIVER_ARRIVING' then
    update public.jobs set status='IN_PROGRESS',started_at=now(),updated_at=now() where id=v_job.id returning * into v_job;
  elsif p_action='COMPLETE' and v_job.status='IN_PROGRESS' then
    update public.jobs set status='COMPLETED',completed_at=now(),final_amount=coalesce(final_amount,estimated_amount),updated_at=now() where id=v_job.id returning * into v_job;
    update public.drivers set status='online',updated_at=now() where id=v_driver.id;
  else
    raise exception 'invalid transition';
  end if;
  insert into public.audit_events(actor_id,entity_type,entity_id,action)
  values(auth.uid(),'JOB',v_job.id,p_action);
  return v_job;
end;
$;
revoke all on function public.driver_job_transition(uuid,text) from public, anon;
grant execute on function public.driver_job_transition(uuid,text) to authenticated;

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
