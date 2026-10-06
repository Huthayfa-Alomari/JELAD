-- JELAD route monitoring v1
create table if not exists public.job_route_points (
  id bigserial primary key,
  job_id uuid not null references public.jobs(id) on delete cascade,
  seq integer not null,
  latitude double precision not null,
  longitude double precision not null,
  created_at timestamptz not null default now(),
  unique(job_id,seq)
);
create index if not exists idx_job_route_points_job_seq on public.job_route_points(job_id,seq);
alter table public.job_route_points enable row level security;
drop policy if exists "job participants read route points" on public.job_route_points;
create policy "job participants read route points" on public.job_route_points for select to authenticated using (exists(select 1 from public.jobs j where j.id=job_id and (j.customer_id=auth.uid() or j.driver_id=auth.uid() or public.is_ops_user())));
drop policy if exists "ops manage route points" on public.job_route_points;
create policy "ops manage route points" on public.job_route_points for all to authenticated using(public.is_ops_user()) with check(public.is_ops_user());