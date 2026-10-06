-- JELAD safety completion v1
alter table public.trusted_contacts
  add column if not exists otp_hmac text,
  add column if not exists otp_expires_at timestamptz,
  add column if not exists otp_attempts integer not null default 0,
  add column if not exists otp_requested_at timestamptz;
create index if not exists idx_trusted_contacts_verification on public.trusted_contacts(user_id,is_verified,otp_expires_at);
drop policy if exists "drivers insert safety evidence" on storage.objects;
create policy "drivers insert safety evidence" on storage.objects for insert to authenticated
with check (bucket_id='safety-evidence' and (storage.foldername(name))[1]='driver' and (storage.foldername(name))[2]=(select auth.uid())::text);
drop policy if exists "drivers insert camera evidence" on public.camera_evidence;
create policy "drivers insert camera evidence" on public.camera_evidence for insert to authenticated
with check (
 exists(select 1 from public.vehicles v join public.jobs j on j.driver_id=v.driver_id
 where v.id=camera_evidence.vehicle_id and j.id=camera_evidence.job_id and v.driver_id=(select auth.uid()) and j.status in ('ASSIGNED','DRIVER_ARRIVING','IN_PROGRESS'))
 and exists(select 1 from public.vehicle_devices d where d.id=camera_evidence.device_id and d.vehicle_id=camera_evidence.vehicle_id and d.status in ('ACTIVE','TAMPERED'))
);