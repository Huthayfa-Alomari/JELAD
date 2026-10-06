-- JELAD safety cron v1
create extension if not exists pg_cron with schema extensions;
select cron.schedule('jelad-safety-stale-gps','* * * * *',$$select public.detect_stale_devices();$$);
