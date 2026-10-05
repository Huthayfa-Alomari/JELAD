import { createClient } from "@/lib/supabase/server";

export async function GET() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const { data, error } = await supabase.rpc("get_driver_jobs");
  if (error) return Response.json({ error: error.message }, { status: 400 });

  const jobs = data || [];
  const locationIds = jobs.flatMap((j: any) => [j.pickup_location_id, j.destination_location_id]).filter(Boolean);
  const { data: locations } = locationIds.length
    ? await supabase.from("locations").select("*").in("id", locationIds)
    : { data: [] };

  const byId = new Map((locations || []).map((l: any) => [l.id, l]));
  return Response.json({
    jobs: jobs.map((j: any) => {
      const assignedToMe = j.driver_id === user.id;
      const mask = (l: any) => assignedToMe || !l ? l : {
        ...l,
        address: "منطقة الالتقاط",
        latitude: Number(Number(l.latitude).toFixed(3)),
        longitude: Number(Number(l.longitude).toFixed(3)),
      };
      const { pin_code: _pin, pin_failed_attempts: _attempts, pin_locked_until: _lock, ...safeJob } = j;
      return {
        ...safeJob,
        pickup: mask(byId.get(j.pickup_location_id)),
        destination: mask(byId.get(j.destination_location_id)),
        privacy: assignedToMe ? "FULL" : "APPROXIMATE",
      };
    }),
  });
}

export async function PATCH(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });
  const body = await req.json();
  const { data, error } = await supabase.rpc("claim_job", { p_job_id: body.jobId });
  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json({ job: data });
}