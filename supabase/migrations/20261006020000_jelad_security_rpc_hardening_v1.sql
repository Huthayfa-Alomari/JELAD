-- JELAD security RPC hardening v1
revoke execute on function public.cancel_customer_job(uuid,text) from anon;
revoke execute on function public.claim_job(uuid) from anon;
revoke execute on function public.driver_job_transition(uuid,text) from anon;
revoke execute on function public.enforce_women_safety_job() from anon;
revoke execute on function public.generate_job_pin() from anon;
revoke execute on function public.get_customer_job_tracking(uuid) from anon;
revoke execute on function public.get_driver_jobs() from anon;
revoke execute on function public.is_driver_user() from anon;
revoke execute on function public.is_ops_user() from anon;
revoke execute on function public.update_driver_location(double precision,double precision) from anon;
revoke execute on function public.update_driver_presence(text) from anon;
revoke execute on function public.verify_trip_start_pin(uuid,text) from anon;
alter function public.dispatch_job(uuid) set search_path=public,pg_temp;
drop policy if exists "drivers read own vehicle" on public.vehicles;
create policy "drivers read own vehicle" on public.vehicles for select to authenticated using (driver_id=(select auth.uid()) or public.is_ops_user());