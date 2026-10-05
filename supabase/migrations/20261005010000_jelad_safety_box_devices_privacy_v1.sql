-- JELAD Safety Box, telemetry, evidence, trusted contacts and privacy controls
-- Technical implementation only; production camera activation requires legal/privacy review.

create table if not exists public.vehicle_devices (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  device_type text not null check (device_type in ('GPS_TRACKER','DRIVER_PHONE','FRONT_CAMERA','INTERIOR_CAMERA','SAFETY_BOX','IMU','OTHER')),
  serial_number text,
  imei text,
  sim_number text,
  provider text,
  status text not null default 'ACTIVE' check (status in ('ACTIVE','INACTIVE','TAMPERED','MAINTENANCE','RETIRED')),
  installed_at timestamptz,
  last_seen_at timestamptz,
  last_latitude double precision,
  last_longitude double precision,
  last_battery_percent numeric(5,2),
  firmware_version text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.device_telemetry (
  id uuid primary key default gen_random_uuid(),
  device_id uuid not null references public.vehicle_devices(id) on delete cascade,
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  recorded_at timestamptz not null default now(),
  latitude double precision,
  longitude double precision,
  speed_kmh numeric(7,2),
  heading numeric(6,2),
  accuracy_m numeric(8,2),
  battery_percent numeric(5,2),
  ignition_on boolean,
  motion_detected boolean,
  raw_payload jsonb not null default '{}'::jsonb
);

create table if not exists public.safety_events (
  id uuid primary key default gen_random_uuid(),
  job_id uuid references public.jobs(id) on delete set null,
  vehicle_id uuid references public.vehicles(id) on delete set null,
  driver_id uuid references public.drivers(id) on delete set null,
  event_type text not null check (event_type in ('SOS','CRASH','ROUTE_DEVIATION','DEVICE_TAMPER','HARSH_BRAKING','HARSH_ACCELERATION','SPEED_ALERT','CAMERA_ALERT','GPS_LOSS','OTHER')),
  severity text not null default 'MEDIUM' check (severity in ('LOW','MEDIUM','HIGH','CRITICAL')),
  status text not null default 'OPEN' check (status in ('OPEN','ACKNOWLEDGED','RESOLVED','FALSE_POSITIVE')),
  latitude double precision,
  longitude double precision,
  occurred_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.camera_evidence (
  id uuid primary key default gen_random_uuid(),
  safety_event_id uuid references public.safety_events(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  device_id uuid not null references public.vehicle_devices(id) on delete cascade,
  camera_type text not null check (camera_type in ('FRONT','INTERIOR','REAR','OTHER')),
  storage_path text not null,
  media_type text not null default 'video',
  captured_at timestamptz not null default now(),
  duration_seconds integer,
  sha256 text,
  encrypted boolean not null default true,
  access_class text not null default 'SAFETY_EVENT' check (access_class in ('SAFETY_EVENT','AUTHORIZED_REVIEW','LEGAL_REQUEST')),
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.evidence_access_logs (
  id uuid primary key default gen_random_uuid(),
  evidence_id uuid not null references public.camera_evidence(id) on delete cascade,
  accessed_by uuid not null,
  purpose text not null,
  accessed_at timestamptz not null default now(),
  ip_hash text,
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists public.trusted_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  contact_name text not null,
  contact_phone text not null,
  relationship text,
  is_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.route_deviation_events (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  vehicle_id uuid references public.vehicles(id) on delete set null,
  driver_id uuid references public.drivers(id) on delete set null,
  detected_at timestamptz not null default now(),
  deviation_meters numeric(10,2) not null,
  duration_seconds integer,
  latitude double precision,
  longitude double precision,
  status text not null default 'OPEN' check (status in ('OPEN','ACKNOWLEDGED','RESOLVED','FALSE_POSITIVE')),
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists public.device_tamper_events (
  id uuid primary key default gen_random_uuid(),
  device_id uuid not null references public.vehicle_devices(id) on delete cascade,
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  detected_at timestamptz not null default now(),
  tamper_type text not null check (tamper_type in ('POWER_LOSS','ENCLOSURE_OPEN','GPS_BLOCKED','SIM_REMOVED','DEVICE_MOVED','OTHER')),
  severity text not null default 'HIGH' check (severity in ('LOW','MEDIUM','HIGH','CRITICAL')),
  latitude double precision,
  longitude double precision,
  resolved_at timestamptz,
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists public.crash_events (
  id uuid primary key default gen_random_uuid(),
  safety_event_id uuid references public.safety_events(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  driver_id uuid references public.drivers(id) on delete set null,
  detected_at timestamptz not null default now(),
  impact_g numeric(8,3),
  latitude double precision,
  longitude double precision,
  auto_sos_triggered boolean not null default false,
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists public.privacy_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  consent_type text not null check (consent_type in ('GPS_TRACKING','SAFETY_CAMERA','INTERIOR_CAMERA','TRUSTED_CONTACTS','IDENTITY_VERIFICATION','DATA_PROCESSING')),
  version text not null,
  granted boolean not null,
  granted_at timestamptz not null default now(),
  withdrawn_at timestamptz,
  metadata jsonb not null default '{}'::jsonb
);

create index if not exists idx_vehicle_devices_vehicle on public.vehicle_devices(vehicle_id);
create index if not exists idx_device_telemetry_device_time on public.device_telemetry(device_id, recorded_at desc);
create index if not exists idx_device_telemetry_job_time on public.device_telemetry(job_id, recorded_at desc);
create index if not exists idx_safety_events_job_time on public.safety_events(job_id, occurred_at desc);
create index if not exists idx_camera_evidence_job on public.camera_evidence(job_id, captured_at desc);
create index if not exists idx_route_deviation_job on public.route_deviation_events(job_id, detected_at desc);
create index if not exists idx_tamper_device_time on public.device_tamper_events(device_id, detected_at desc);
create index if not exists idx_crash_job_time on public.crash_events(job_id, detected_at desc);
create index if not exists idx_privacy_consents_user on public.privacy_consents(user_id, consent_type, granted_at desc);

alter table public.vehicle_devices enable row level security;
alter table public.device_telemetry enable row level security;
alter table public.safety_events enable row level security;
alter table public.camera_evidence enable row level security;
alter table public.evidence_access_logs enable row level security;
alter table public.trusted_contacts enable row level security;
alter table public.route_deviation_events enable row level security;
alter table public.device_tamper_events enable row level security;
alter table public.crash_events enable row level security;
alter table public.privacy_consents enable row level security;

create policy "drivers view own vehicle devices" on public.vehicle_devices for select to authenticated using (
  exists (select 1 from public.vehicles v join public.drivers d on d.id=v.driver_id where v.id=vehicle_devices.vehicle_id and d.id=(select auth.uid()))
);
create policy "users view own trusted contacts" on public.trusted_contacts for select to authenticated using (user_id=(select auth.uid()));
create policy "users manage own trusted contacts" on public.trusted_contacts for all to authenticated using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()));
create policy "users view own consents" on public.privacy_consents for select to authenticated using (user_id=(select auth.uid()));
create policy "users manage own consents" on public.privacy_consents for all to authenticated using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()));

create policy "drivers view own telemetry" on public.device_telemetry for select to authenticated using (
  exists (select 1 from public.vehicles v join public.drivers d on d.id=v.driver_id where v.id=device_telemetry.vehicle_id and d.id=(select auth.uid()))
);
create policy "job participants view safety events" on public.safety_events for select to authenticated using (
  exists (select 1 from public.jobs j where j.id=safety_events.job_id and (j.customer_id=(select auth.uid()) or j.driver_id=(select auth.uid())))
  or public.is_ops_user()
);
create policy "ops manage safety events" on public.safety_events for all to authenticated using (public.is_ops_user()) with check (public.is_ops_user());
create policy "ops view camera evidence" on public.camera_evidence for select to authenticated using (public.is_ops_user());
create policy "ops manage evidence access logs" on public.evidence_access_logs for all to authenticated using (public.is_ops_user());
create policy "job participants view route deviation" on public.route_deviation_events for select to authenticated using (
  exists (select 1 from public.jobs j where j.id=route_deviation_events.job_id and (j.customer_id=(select auth.uid()) or j.driver_id=(select auth.uid())))
  or public.is_ops_user()
);
create policy "ops manage route deviation" on public.route_deviation_events for all to authenticated using (public.is_ops_user()) with check (public.is_ops_user());
create policy "ops view tamper events" on public.device_tamper_events for select to authenticated using (public.is_ops_user());
create policy "ops view crash events" on public.crash_events for select to authenticated using (public.is_ops_user());
create policy "ops view telemetry" on public.device_telemetry for select to authenticated using (public.is_ops_user());

create or replace function public.record_device_telemetry(
  p_device_id uuid, p_vehicle_id uuid, p_job_id uuid, p_lat double precision, p_lng double precision,
  p_speed numeric default null, p_heading numeric default null, p_accuracy numeric default null,
  p_battery numeric default null, p_ignition boolean default null, p_motion boolean default null
) returns uuid
language plpgsql security invoker set search_path=public
as $$
declare v_id uuid;
begin
  if not exists (select 1 from public.vehicle_devices d where d.id=p_device_id and d.vehicle_id=p_vehicle_id) then
    raise exception 'DEVICE_VEHICLE_MISMATCH';
  end if;
  insert into public.device_telemetry(device_id,vehicle_id,job_id,latitude,longitude,speed_kmh,heading,accuracy_m,battery_percent,ignition_on,motion_detected)
  values(p_device_id,p_vehicle_id,p_job_id,p_lat,p_lng,p_speed,p_heading,p_accuracy,p_battery,p_ignition,p_motion)
  returning id into v_id;
  update public.vehicle_devices set last_seen_at=now(),last_latitude=p_lat,last_longitude=p_lng,last_battery_percent=p_battery,updated_at=now() where id=p_device_id;
  return v_id;
end $$;

grant execute on function public.record_device_telemetry(uuid,uuid,uuid,double precision,double precision,numeric,numeric,numeric,numeric,boolean,boolean) to authenticated;
