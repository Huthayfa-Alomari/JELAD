drop policy if exists "trip_live_locations_public_read" on public.trip_live_locations;

create policy "trip_live_locations_participant_read"
on public.trip_live_locations
for select to authenticated
using (
  exists (
    select 1 from public.jobs j
    where j.id=trip_live_locations.job_id
      and (j.customer_id=auth.uid() or j.driver_id=auth.uid())
  )
);
