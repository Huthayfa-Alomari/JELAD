create table if not exists public.fare_rules (
  job_type public.job_type primary key,
  base_fare numeric(10,3) not null default 0.750,
  per_km numeric(10,3) not null default 0.350,
  per_minute numeric(10,3) not null default 0.080,
  minimum_fare numeric(10,3) not null default 1.500,
  booking_fee numeric(10,3) not null default 0.000,
  active boolean not null default true,
  updated_at timestamptz not null default now()
);

insert into public.fare_rules(job_type,base_fare,per_km,per_minute,minimum_fare)
values
 ('RIDE',0.750,0.350,0.080,1.500),
 ('DELIVERY',1.000,0.450,0.080,2.000),
 ('CARGO',2.000,0.650,0.100,4.000)
on conflict (job_type) do nothing;

alter table public.fare_rules enable row level security;
drop policy if exists "fare_rules_ops_read" on public.fare_rules;
create policy "fare_rules_ops_read" on public.fare_rules for select to authenticated using (public.is_ops_user());

create or replace function public.quote_job_fare(p_type public.job_type,p_pickup_lat double precision,p_pickup_lng double precision,p_destination_lat double precision,p_destination_lng double precision,p_estimated_minutes integer default null)
returns jsonb language plpgsql security definer set search_path=public as $$
declare r public.fare_rules; v_distance_km numeric; v_minutes numeric; v_amount numeric;
begin
 select * into r from public.fare_rules where job_type=p_type and active;
 if not found then raise exception 'fare rule not configured for %',p_type; end if;
 v_distance_km := 6371.0088 * 2 * asin(sqrt(power(sin(radians(p_destination_lat-p_pickup_lat)/2),2)+cos(radians(p_pickup_lat))*cos(radians(p_destination_lat))*power(sin(radians(p_destination_lng-p_pickup_lng)/2),2)));
 v_distance_km := greatest(v_distance_km,0);
 v_minutes := greatest(coalesce(p_estimated_minutes,ceil(v_distance_km / 0.55 * 60)),1);
 v_amount := greatest(r.minimum_fare,r.base_fare+r.booking_fee+(r.per_km*v_distance_km)+(r.per_minute*v_minutes));
 return jsonb_build_object('currency','JOD','amount',round(v_amount,3),'distance_km',round(v_distance_km,2),'estimated_minutes',ceil(v_minutes),'rule',jsonb_build_object('base',r.base_fare,'per_km',r.per_km,'per_minute',r.per_minute,'minimum',r.minimum_fare),'estimate_method','geodesic');
end; $$;

revoke all on function public.quote_job_fare(public.job_type,double precision,double precision,double precision,double precision,integer) from public;
grant execute on function public.quote_job_fare(public.job_type,double precision,double precision,double precision,double precision,integer) to authenticated;

create or replace function public.create_job(p_type public.job_type,p_pickup_address text,p_pickup_lat double precision,p_pickup_lng double precision,p_destination_address text,p_destination_lat double precision,p_destination_lng double precision,p_estimated_amount numeric default 0,p_notes text default null)
returns public.jobs language plpgsql set search_path=public as $$
declare v_job public.jobs; v_pickup uuid; v_destination uuid; v_quote jsonb; v_amount numeric;
begin
 if auth.uid() is null then raise exception 'not authenticated'; end if;
 if p_pickup_lat not between -90 and 90 or p_destination_lat not between -90 and 90 or p_pickup_lng not between -180 and 180 or p_destination_lng not between -180 and 180 then raise exception 'invalid coordinates'; end if;
 if abs(p_pickup_lat)<0.000001 and abs(p_pickup_lng)<0.000001 then raise exception 'pickup coordinates required'; end if;
 if abs(p_destination_lat)<0.000001 and abs(p_destination_lng)<0.000001 then raise exception 'destination coordinates required'; end if;
 v_quote:=public.quote_job_fare(p_type,p_pickup_lat,p_pickup_lng,p_destination_lat,p_destination_lng,null);
 v_amount:=greatest(coalesce(p_estimated_amount,0),0);
 if v_amount=0 then v_amount:=(v_quote->>'amount')::numeric; end if;
 insert into public.locations(owner_id,label,address,latitude,longitude) values(auth.uid(),'Pickup',p_pickup_address,p_pickup_lat,p_pickup_lng) returning id into v_pickup;
 insert into public.locations(owner_id,label,address,latitude,longitude) values(auth.uid(),'Destination',p_destination_address,p_destination_lat,p_destination_lng) returning id into v_destination;
 insert into public.jobs(customer_id,type,status,pickup_location_id,destination_location_id,estimated_amount,price_breakdown,notes) values(auth.uid(),p_type,'REQUESTED',v_pickup,v_destination,v_amount,v_quote,p_notes) returning * into v_job;
 return v_job;
end; $$;
