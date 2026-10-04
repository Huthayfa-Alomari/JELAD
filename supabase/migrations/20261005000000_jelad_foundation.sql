create extension if not exists pgcrypto;

create type public.user_role as enum ('CUSTOMER','DRIVER','DISPATCHER','ADMIN','CORPORATE_ADMIN','SUPPORT');
create type public.job_type as enum ('RIDE','DELIVERY','CARGO','CORPORATE_TRIP');
create type public.job_status as enum ('REQUESTED','SEARCHING','ASSIGNED','DRIVER_ARRIVING','IN_PROGRESS','COMPLETED','CANCELLED','REJECTED','EXPIRED');
create type public.payment_status as enum ('PENDING','AUTHORIZED','PAID','FAILED','REFUNDED');

create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text,
 phone text,
 avatar_url text,
 role public.user_role not null default 'CUSTOMER',
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table public.drivers (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null unique references public.profiles(id) on delete cascade,
 license_number text,
 status text not null default 'OFFLINE',
 rating numeric(3,2) not null default 5.00,
 verified_at timestamptz,
 created_at timestamptz not null default now()
);
create table public.vehicles (
 id uuid primary key default gen_random_uuid(),
 driver_id uuid not null references public.drivers(id) on delete cascade,
 make text not null, model text not null, year int,
 plate_number text not null unique, color text, capacity int not null default 4,
 created_at timestamptz not null default now()
);
create table public.locations (
 id uuid primary key default gen_random_uuid(),
 user_id uuid references public.profiles(id) on delete cascade,
 label text, address text not null,
 latitude numeric(9,6), longitude numeric(9,6),
 created_at timestamptz not null default now()
);
create table public.jobs (
 id uuid primary key default gen_random_uuid(),
 customer_id uuid references public.profiles(id),
 driver_id uuid references public.drivers(id),
 type public.job_type not null,
 status public.job_status not null default 'REQUESTED',
 pickup_location_id uuid references public.locations(id),
 destination_location_id uuid references public.locations(id),
 scheduled_at timestamptz,
 quoted_amount numeric(12,3),
 final_amount numeric(12,3),
 notes text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table public.payments (
 id uuid primary key default gen_random_uuid(),
 job_id uuid not null references public.jobs(id) on delete cascade,
 customer_id uuid not null references public.profiles(id),
 amount numeric(12,3) not null,
 currency char(3) not null default 'JOD',
 status public.payment_status not null default 'PENDING',
 provider text,
 provider_reference text,
 created_at timestamptz not null default now()
);
create table public.wallet_ledger (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 job_id uuid references public.jobs(id),
 direction text not null check (direction in ('CREDIT','DEBIT')),
 amount numeric(12,3) not null check (amount >= 0),
 balance_after numeric(12,3) not null,
 description text,
 created_at timestamptz not null default now()
);
create table public.ratings (
 id uuid primary key default gen_random_uuid(),
 job_id uuid not null unique references public.jobs(id) on delete cascade,
 rater_id uuid not null references public.profiles(id),
 ratee_id uuid not null references public.profiles(id),
 score int not null check (score between 1 and 5),
 comment text,
 created_at timestamptz not null default now()
);
create table public.safety_incidents (
 id uuid primary key default gen_random_uuid(),
 job_id uuid references public.jobs(id),
 reporter_id uuid references public.profiles(id),
 severity text not null default 'LOW',
 status text not null default 'OPEN',
 description text not null,
 created_at timestamptz not null default now()
);
create table public.audit_events (
 id uuid primary key default gen_random_uuid(),
 actor_id uuid references public.profiles(id),
 entity_type text not null,
 entity_id uuid,
 action text not null,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.drivers enable row level security;
alter table public.vehicles enable row level security;
alter table public.locations enable row level security;
alter table public.jobs enable row level security;
alter table public.payments enable row level security;
alter table public.wallet_ledger enable row level security;
alter table public.ratings enable row level security;
alter table public.safety_incidents enable row level security;
alter table public.audit_events enable row level security;

create policy "profiles_self_select" on public.profiles for select to authenticated using ((select auth.uid())=id);
create policy "profiles_self_update" on public.profiles for update to authenticated using ((select auth.uid())=id) with check ((select auth.uid())=id);
create policy "locations_owner" on public.locations for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy "jobs_customer_select" on public.jobs for select to authenticated using ((select auth.uid())=customer_id);
create policy "jobs_customer_insert" on public.jobs for insert to authenticated with check ((select auth.uid())=customer_id);
create policy "payments_customer_select" on public.payments for select to authenticated using ((select auth.uid())=customer_id);
create policy "wallet_self_select" on public.wallet_ledger for select to authenticated using ((select auth.uid())=user_id);
create policy "ratings_rater_select" on public.ratings for select to authenticated using ((select auth.uid())=rater_id or (select auth.uid())=ratee_id);
create policy "safety_reporter_select" on public.safety_incidents for select to authenticated using ((select auth.uid())=reporter_id);
create policy "audit_actor_select" on public.audit_events for select to authenticated using ((select auth.uid())=actor_id);

create index jobs_customer_idx on public.jobs(customer_id, created_at desc);
create index jobs_driver_idx on public.jobs(driver_id, status);
create index jobs_status_idx on public.jobs(status, created_at desc);
create index payments_customer_idx on public.payments(customer_id, created_at desc);
create index audit_entity_idx on public.audit_events(entity_type, entity_id, created_at desc);