create or replace function public.get_driver_job_tracking(p_job_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_job public.jobs;
  v_pickup public.locations;
  v_destination public.locations;
  v_driver public.drivers;
  v_profile public.profiles;
  v_vehicle public.vehicles;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;

  select * into v_job from public.jobs where id=p_job_id and driver_id=auth.uid();
  if v_job.id is null then raise exception 'job not assigned to current driver'; end if;

  select * into v_pickup from public.locations where id=v_job.pickup_location_id;
  select * into v_destination from public.locations where id=v_job.destination_location_id;
  select * into v_driver from public.drivers where id=auth.uid();
  select * into v_profile from public.profiles where id=auth.uid();
  select * into v_vehicle from public.vehicles where driver_id=auth.uid() order by created_at desc limit 1;

  return jsonb_build_object(
    'job', jsonb_build_object(
      'id',v_job.id,'status',v_job.status,'type',v_job.type,
      'quoted_amount',v_job.quoted_amount,'final_amount',v_job.final_amount,
      'notes',v_job.notes,'created_at',v_job.created_at,'updated_at',v_job.updated_at
    ),
    'pickup', case when v_pickup.id is null then null else jsonb_build_object(
      'latitude',v_pickup.latitude,'longitude',v_pickup.longitude,'address',v_pickup.address) end,
    'destination', case when v_destination.id is null then null else jsonb_build_object(
      'latitude',v_destination.latitude,'longitude',v_destination.longitude,'address',v_destination.address) end,
    'driver', jsonb_build_object(
      'id',v_driver.id,'name',coalesce(v_profile.full_name,'JELAD Driver'),
      'rating',v_driver.rating,
      'vehicle',case when v_vehicle.id is null then null else jsonb_build_object(
        'make',v_vehicle.make,'model',v_vehicle.model,'plate',v_vehicle.plate_number,'color',v_vehicle.color) end
    )
  );
end;
$$;

revoke all on function public.get_driver_job_tracking(uuid) from public;
grant execute on function public.get_driver_job_tracking(uuid) to authenticated;
