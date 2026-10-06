-- JELAD security public grants v2
revoke execute on function public.claim_job(uuid) from public; grant execute on function public.claim_job(uuid) to authenticated;
revoke execute on function public.enforce_women_safety_job() from public;
revoke execute on function public.generate_job_pin() from public; grant execute on function public.generate_job_pin() to authenticated;
revoke execute on function public.is_driver_user() from public; grant execute on function public.is_driver_user() to authenticated;
revoke execute on function public.is_ops_user() from public; grant execute on function public.is_ops_user() to authenticated;
revoke execute on function public.update_driver_location(double precision,double precision) from public; grant execute on function public.update_driver_location(double precision,double precision) to authenticated;
revoke execute on function public.update_driver_presence(text) from public; grant execute on function public.update_driver_presence(text) to authenticated;
revoke execute on function public.cancel_customer_job(uuid,text) from public; grant execute on function public.cancel_customer_job(uuid,text) to authenticated;
revoke execute on function public.driver_job_transition(uuid,text) from public; grant execute on function public.driver_job_transition(uuid,text) to authenticated;
revoke execute on function public.get_customer_job_tracking(uuid) from public; grant execute on function public.get_customer_job_tracking(uuid) to authenticated;
revoke execute on function public.get_driver_jobs() from public; grant execute on function public.get_driver_jobs() to authenticated;
revoke execute on function public.verify_trip_start_pin(uuid,text) from public; grant execute on function public.verify_trip_start_pin(uuid,text) to authenticated;
revoke execute on function public.detect_stale_devices() from public; grant execute on function public.detect_stale_devices() to authenticated;

-- v3: keep internal-only helpers and public share RPC closed by default
revoke execute on function public.enforce_women_safety_job() from authenticated;
revoke execute on function public.generate_job_pin() from authenticated;
revoke execute on function public.is_driver_user() from authenticated;
revoke execute on function public.is_ops_user() from authenticated;
revoke execute on function public.get_public_trip_tracking(uuid) from anon, authenticated;
