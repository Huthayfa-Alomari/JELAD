import { createClient } from "@/lib/supabase/server";

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const body = await req.json().catch(() => ({}));
  const jobId = String(body.jobId || "");
  if (!jobId) return Response.json({ error: "jobId is required" }, { status: 400 });

  const { data: job, error } = await supabase
    .from("jobs")
    .select("id,status,share_token,customer_id,driver_id")
    .eq("id", jobId)
    .maybeSingle();

  if (error) return Response.json({ error: error.message }, { status: 400 });
  if (!job) return Response.json({ error: "Trip not found" }, { status: 404 });
  if (job.customer_id !== user.id && job.driver_id !== user.id) {
    return Response.json({ error: "Trip access denied" }, { status: 403 });
  }
  if (!["ASSIGNED", "DRIVER_ARRIVING", "IN_PROGRESS"].includes(job.status)) {
    return Response.json({ error: "Trip sharing is only available for active trips" }, { status: 409 });
  }

  return Response.json({
    jobId: job.id,
    shareToken: job.share_token,
    shareUrl: `/track/${job.share_token}`
  });
}

export async function GET(req: Request) {
  const supabase = await createClient();
  const token = new URL(req.url).searchParams.get("token");
  if (!token) return Response.json({ error: "token is required" }, { status: 400 });

  const { data, error } = await supabase
    .from("trip_live_locations")
    .select("job_id,share_token,latitude,longitude,updated_at")
    .eq("share_token", token)
    .maybeSingle();

  if (error) return Response.json({ error: error.message }, { status: 400 });
  if (!data) return Response.json({ error: "Tracking unavailable" }, { status: 404 });

  return Response.json({
    tracking: {
      jobId: data.job_id,
      latitude: data.latitude,
      longitude: data.longitude,
      updatedAt: data.updated_at
    }
  }, { headers: { "Cache-Control": "no-store" } });
}
