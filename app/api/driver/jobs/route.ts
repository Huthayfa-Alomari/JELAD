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
    jobs: jobs.map((j: any) => ({
      ...j,
      pickup: byId.get(j.pickup_location_id) || null,
      destination: byId.get(j.destination_location_id) || null,
    })),
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