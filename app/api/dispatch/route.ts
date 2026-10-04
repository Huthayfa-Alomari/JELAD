import { NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(req: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const body = await req.json();
  const jobId = String(body.jobId || "");
  if (!jobId) return Response.json({ error: "jobId is required" }, { status: 400 });

  const { data: job, error } = await supabase.rpc("dispatch_job", { p_job_id: jobId });
  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json({ job });
}
