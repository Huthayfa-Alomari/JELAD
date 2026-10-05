-- JELAD Safety Engine v2
create table if not exists public.safety_rules (
  id uuid primary key default gen_random_uuid(),
  rule_key text unique not null,
  enabled boolean not null default true,
  threshold_numeric numeric,
  threshold_seconds integer,
  severity text not null default 'HIGH',
  metadata jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

insert into public.safety_rules(rule_key,threshold_numeric,threshold_seconds,severity,metadata) values
('SPEED_ALERT_KMH',120,null,'HIGH','{"critical_at":150}'),
('ROUTE_DEVIATION_METERS',250,60,'HIGH','{"description":"Distance from planned route"}'),
('GPS_LOSS_SECONDS',90,90,'HIGH','{"critical_after":300}'),
('CRASH_IMPACT_G',2.5,null,'CRITICAL','{"auto_sos":true}'),
('DEVICE_TAMPER',null,0,'HIGH','{"critical_types":["POWER_LOSS","GPS_BLOCKED","SIM_REMOVED"]}')
on conflict(rule_key) do nothing;

create table if not exists public.notification_outbox (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  event_type text not null,
  channel text not null default 'IN_APP',
  recipient text,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'PENDING',
  attempts integer not null default 0,
  available_at timestamptz not null default now(),
  sent_at timestamptz,
  last_error text,
  created_at timestamptz not null default now()
);

create index if not exists idx_notification_outbox_pending on public.notification_outbox(status,available_at);
create index if not exists idx_safety_rules_key on public.safety_rules(rule_key);

alter table public.safety_rules enable row level security;
alter table public.notification_outbox enable row level security;

drop policy if exists "ops manage safety rules" on public.safety_rules;
create policy "ops manage safety rules" on public.safety_rules for all to authenticated using (public.is_ops_user()) with check (public.is_ops_user());
drop policy if exists "users read own notifications" on public.notification_outbox;
create policy "users read own notifications" on public.notification_outbox for select to authenticated using (user_id=(select auth.uid()));
drop policy if exists "ops manage notification outbox" on public.notification_outbox;
create policy "ops manage notification outbox" on public.notification_outbox for all to authenticated using (public.is_ops_user()) with check (public.is_ops_user());

create or replace function public.enqueue_notification(p_user_id uuid,p_job_id uuid,p_event_type text,p_channel text,p_recipient text,p_payload jsonb default '{}'::jsonb)
returns uuid language plpgsql security invoker set search_path=public as $$
declare v_id uuid;
begin
 if auth.uid() is null then raise exception 'authentication required'; end if;
 if not (auth.uid()=p_user_id or public.is_ops_user()) then raise exception 'notification access denied'; end if;
 insert into public.notification_outbox(user_id,job_id,event_type,channel,recipient,payload)
 values(p_user_id,p_job_id,upper(p_event_type),upper(p_channel),p_recipient,coalesce(p_payload,'{}'::jsonb))
 returning id into v_id; return v_id;
end $$;
grant execute on function public.enqueue_notification(uuid,uuid,text,text,text,jsonb) to authenticated;

create or replace function public.record_crash_event(p_job_id uuid,p_vehicle_id uuid,p_driver_id uuid,p_impact_g numeric,p_lat double precision default null,p_lng double precision default null,p_metadata jsonb default '{}'::jsonb)
returns uuid language plpgsql security invoker set search_path=public as $$
declare v_id uuid; v_event uuid; v_threshold numeric := coalesce((select threshold_numeric from public.safety_rules where rule_key='CRASH_IMPACT_G'),2.5); v_sos boolean := p_impact_g >= v_threshold; v_customer uuid;
begin
 if auth.uid() is null then raise exception 'authentication required'; end if;
 if not exists(select 1 from public.vehicles v where v.id=p_vehicle_id and v.driver_id=auth.uid()) then raise exception 'vehicle access denied'; end if;
 if p_job_id is not null and not exists(select 1 from public.jobs j where j.id=p_job_id and j.driver_id=auth.uid() and j.status in ('ASSIGNED','DRIVER_ARRIVING','IN_PROGRESS')) then raise exception 'job access denied'; end if;
 insert into public.safety_events(job_id,vehicle_id,driver_id,event_type,severity,status,latitude,longitude,metadata)
 values(p_job_id,p_vehicle_id,p_driver_id,'CRASH',case when v_sos then 'CRITICAL' else 'HIGH' end,'OPEN',p_lat,p_lng,coalesce(p_metadata,'{}'::jsonb)||jsonb_build_object('impact_g',p_impact_g)) returning id into v_event;
 insert into public.crash_events(safety_event_id,job_id,vehicle_id,driver_id,impact_g,latitude,longitude,auto_sos_triggered,metadata)
 values(v_event,p_job_id,p_vehicle_id,p_driver_id,p_impact_g,p_lat,p_lng,v_sos,coalesce(p_metadata,'{}'::jsonb)) returning id into v_id;
 if v_sos and p_job_id is not null then
   select customer_id into v_customer from public.jobs where id=p_job_id;
   insert into public.safety_incidents(job_id,reporter_id,category,description,severity,status)
   values(p_job_id,auth.uid(),'ACCIDENT','Automatic crash detection triggered emergency safety workflow.','critical','open');
   if v_customer is not null then
     insert into public.notification_outbox(user_id,job_id,event_type,channel,payload)
     values(v_customer,p_job_id,'CRASH_AUTO_SOS','IN_APP',jsonb_build_object('severity','CRITICAL','impact_g',p_impact_g));
   end if;
 end if;
 return v_id;
end $$;
grant execute on function public.record_crash_event(uuid,uuid,uuid,numeric,double precision,double precision,jsonb) to authenticated;

create or replace function public.record_route_deviation(p_job_id uuid,p_vehicle_id uuid,p_driver_id uuid,p_deviation_meters numeric,p_duration_seconds integer,p_lat double precision default null,p_lng double precision default null,p_metadata jsonb default '{}'::jsonb)
returns uuid language plpgsql security invoker set search_path=public as $$
declare v_id uuid; v_threshold numeric; v_duration integer;
begin
 if auth.uid() is null then raise exception 'authentication required'; end if;
 if not exists(select 1 from public.vehicles v where v.id=p_vehicle_id and v.driver_id=auth.uid()) then raise exception 'vehicle access denied'; end if;
 if not exists(select 1 from public.jobs j where j.id=p_job_id and j.driver_id=auth.uid() and j.status in ('ASSIGNED','DRIVER_ARRIVING','IN_PROGRESS')) then raise exception 'job access denied'; end if;
 select threshold_numeric,threshold_seconds into v_threshold,v_duration from public.safety_rules where rule_key='ROUTE_DEVIATION_METERS';
 if p_deviation_meters < coalesce(v_threshold,250) or p_duration_seconds < coalesce(v_duration,60) then return null; end if;
 insert into public.route_deviation_events(job_id,vehicle_id,driver_id,deviation_meters,duration_seconds,latitude,longitude,status,metadata)
 values(p_job_id,p_vehicle_id,p_driver_id,p_deviation_meters,p_duration_seconds,p_lat,p_lng,'OPEN',coalesce(p_metadata,'{}'::jsonb)) returning id into v_id;
 insert into public.safety_events(job_id,vehicle_id,driver_id,event_type,severity,status,latitude,longitude,metadata)
 values(p_job_id,p_vehicle_id,p_driver_id,'ROUTE_DEVIATION','HIGH','OPEN',p_lat,p_lng,jsonb_build_object('deviation_meters',p_deviation_meters,'duration_seconds',p_duration_seconds));
 return v_id;
end $$;
grant execute on function public.record_route_deviation(uuid,uuid,uuid,numeric,integer,double precision,double precision,jsonb) to authenticated;

create or replace function public.record_device_tamper(p_device_id uuid,p_vehicle_id uuid,p_job_id uuid,p_tamper_type text,p_lat double precision default null,p_lng double precision default null,p_metadata jsonb default '{}'::jsonb)
returns uuid language plpgsql security invoker set search_path=public as $$
declare v_id uuid; v_driver uuid; v_severity text;
begin
 if auth.uid() is null then raise exception 'authentication required'; end if;
 select driver_id into v_driver from public.vehicles where id=p_vehicle_id and driver_id=auth.uid();
 if v_driver is null then raise exception 'vehicle access denied'; end if;
 if not exists(select 1 from public.vehicle_devices where id=p_device_id and vehicle_id=p_vehicle_id) then raise exception 'device access denied'; end if;
 v_severity := case when upper(p_tamper_type) in ('POWER_LOSS','GPS_BLOCKED','SIM_REMOVED') then 'CRITICAL' else 'HIGH' end;
 insert into public.device_tamper_events(device_id,vehicle_id,job_id,tamper_type,severity,latitude,longitude,metadata)
 values(p_device_id,p_vehicle_id,p_job_id,upper(p_tamper_type),v_severity,p_lat,p_lng,coalesce(p_metadata,'{}'::jsonb)) returning id into v_id;
 update public.vehicle_devices set status='TAMPERED',updated_at=now() where id=p_device_id;
 insert into public.safety_events(job_id,vehicle_id,driver_id,event_type,severity,status,latitude,longitude,metadata)
 values(p_job_id,p_vehicle_id,v_driver,'DEVICE_TAMPER',v_severity,'OPEN',p_lat,p_lng,jsonb_build_object('device_id',p_device_id,'tamper_type',upper(p_tamper_type)));
 return v_id;
end $$;
grant execute on function public.record_device_tamper(uuid,uuid,uuid,text,double precision,double precision,jsonb) to authenticated;

create or replace function public.detect_stale_devices()
returns integer language plpgsql security definer set search_path=public as $$
declare r record; v_count integer := 0; v_limit integer := coalesce((select threshold_seconds from public.safety_rules where rule_key='GPS_LOSS_SECONDS'),90);
begin
 for r in
  select d.id,d.vehicle_id,j.id job_id,v.driver_id
  from public.vehicle_devices d join public.vehicles v on v.id=d.vehicle_id
  left join lateral (select id from public.jobs where driver_id=v.driver_id and status in ('ASSIGNED','DRIVER_ARRIVING','IN_PROGRESS') order by updated_at desc limit 1) j on true
  where d.status='ACTIVE' and d.last_seen_at is not null and d.last_seen_at < now() - make_interval(secs=>v_limit)
 loop
  if not exists(select 1 from public.safety_events e where e.vehicle_id=r.vehicle_id and e.event_type='GPS_LOSS' and e.occurred_at > now()-interval '10 minutes') then
   insert into public.safety_events(job_id,vehicle_id,driver_id,event_type,severity,status,metadata)
   values(r.job_id,r.vehicle_id,r.driver_id,'GPS_LOSS','HIGH','OPEN',jsonb_build_object('device_id',r.id));
   v_count:=v_count+1;
  end if;
 end loop;
 return v_count;
end $$;
revoke execute on function public.detect_stale_devices() from public,anon;
grant execute on function public.detect_stale_devices() to authenticated;
