-- Payment idempotency and reusable PayTabs checkout state.
alter table public.payments add column if not exists checkout_url text;
alter table public.payments add column if not exists initiated_at timestamptz;
create index if not exists payments_job_provider_status_idx on public.payments(job_id, provider, status, created_at desc);
create unique index if not exists payments_one_pending_paytabs_per_job on public.payments(job_id) where provider='PAYTABS' and status in ('PENDING','AUTHORIZED');
