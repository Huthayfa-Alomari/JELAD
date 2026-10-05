-- JELAD safety runtime hardening v1
-- Tightens telemetry/SOS authorization and audited evidence access.

create policy "authenticated safety incident reporter insert"
on public.safety_incidents for insert to authenticated
with check (
  reporter_id = (select auth.uid())
  and (
    job_id is null
    or exists (
      select 1 from public.jobs j
      where j.id = safety_incidents.job_id
        and (j.customer_id = (select auth.uid()) or j.driver_id = (select auth.uid()))
    )
  )
);

create policy "job participants insert safety events"
on public.safety_events for insert to authenticated
with check (
  exists (
    select 1 from public.jobs j
    where j.id = safety_events.job_id
      and (j.customer_id = (select auth.uid()) or j.driver_id = (select auth.uid()))
  )
  and driver_id is not null
);

create policy "drivers insert own telemetry"
on public.device_telemetry for insert to authenticated
with check (
  exists (select 1 from public.vehicles v where v.id=device_telemetry.vehicle_id and v.driver_id=(select auth.uid()))
  and exists (select 1 from public.vehicle_devices d where d.id=device_telemetry.device_id and d.vehicle_id=device_telemetry.vehicle_id)
);

create or replace function public.create_sos_incident(
  p_job_id uuid, p_description text default null
) returns public.safety_incidents
language plpgsql
security invoker
set search_path=public
as $$
declare v_incident public.safety_incidents;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  if p_job_id is null then
    insert into public.safety_incidents(job_id,reporter_id,category,description,severity,status)
    values(null,auth.uid(),'SOS',left(coalesce(p_description,'Emergency assistance requested'),1000),'CRITICAL','open')
    returning * into v_incident;
  else
    if not exists (
      select 1 from public.jobs j
      where j.id=p_job_id
        and (j.customer_id=auth.uid() or j.driver_id=auth.uid())
        and j.status in ('ASSIGNED','DRIVER_ARRIVING','IN_PROGRESS')
    ) then raise exception 'active job access required'; end if;

    insert into public.safety_incidents(job_id,reporter_id,category,description,severity,status)
    values(p_job_id,auth.uid(),'SOS',left(coalesce(p_description,'Emergency assistance requested'),1000),'CRITICAL','open')
    returning * into v_incident;

    insert into public.safety_events(job_id,driver_id,event_type,severity,status,occurred_at,metadata)
    select p_job_id,j.driver_id,'SOS','CRITICAL','OPEN',now(),
           jsonb_build_object('reporter_id',auth.uid(),'source','app')
    from public.jobs j where j.id=p_job_id;
  end if;

  insert into public.audit_events(actor_id,entity_type,entity_id,action,metadata)
  values(auth.uid(),'SAFETY_INCIDENT',v_incident.id,'SOS_TRIGGERED',jsonb_build_object('job_id',p_job_id));

  return v_incident;
end $$;

grant execute on function public.create_sos_incident(uuid,text) to authenticated;

create or replace function public.record_device_telemetry(
  p_device_id uuid, p_vehicle_id uuid, p_job_id uuid, p_lat double precision, p_lng double precision,
  p_speed numeric default null, p_heading numeric default null, p_accuracy numeric default null,
  p_battery numeric default null, p_ignition boolean default null, p_motion boolean default null
) returns uuid
language plpgsql
security invoker
set search_path=public
as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  if not exists (select 1 from public.vehicles v where v.id=p_vehicle_id and v.driver_id=auth.uid()) then raise exception 'vehicle access denied'; end if;
  if not exists (select 1 from public.vehicle_devices d where d.id=p_device_id and d.vehicle_id=p_vehicle_id and d.status in ('ACTIVE','TAMPERED')) then raise exception 'device access denied'; end if;
  if p_job_id is not null and not exists (
    select 1 from public.jobs j where j.id=p_job_id and j.driver_id=auth.uid() and j.status in ('ASSIGNED','DRIVER_ARRIVING','IN_PROGRESS')
  ) then raise exception 'job access denied'; end if;
  insert into public.device_telemetry(device_id,vehicle_id,job_id,latitude,longitude,speed_kmh,heading,accuracy_m,battery_percent,ignition_on,motion_detected)
  values(p_device_id,p_vehicle_id,p_job_id,p_lat,p_lng,p_speed,p_heading,p_accuracy,p_battery,p_ignition,p_motion)
  returning id into v_id;
  update public.vehicle_devices set last_seen_at=now(),last_latitude=p_lat,last_longitude=p_lng,last_battery_percent=p_battery,updated_at=now() where id=p_device_id;
  return v_id;
end $$;

grant execute on function public.record_device_telemetry(uuid,uuid,uuid,double precision,double precision,numeric,numeric,numeric,numeric,boolean,boolean) to authenticated;

create policy "ops read safety evidence storage"
on storage.objects for select to authenticated
using (bucket_id='safety-evidence' and public.is_ops_user());

create policy "ops insert safety evidence storage"
on storage.objects for insert to authenticated
with check (bucket_id='safety-evidence' and public.is_ops_user());

create policy "ops delete safety evidence storage"
on storage.objects for delete to authenticated
using (bucket_id='safety-evidence' and public.is_ops_user());
