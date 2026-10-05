import { createClient } from "@/lib/supabase/server";

const ALLOWED_CATEGORIES = new Set(["SOS", "ACCIDENT", "MEDICAL", "HARASSMENT", "OTHER"]);
const ALLOWED_SEVERITIES = new Set(["LOW", "MEDIUM", "HIGH", "CRITICAL"]);

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const body = await req.json().catch(() => ({}));
  const jobId = body.jobId ? String(body.jobId) : null;
  const category = String(body.category || "SOS").toUpperCase();
  const severity = String(body.severity || "HIGH").toUpperCase();
  const description = String(body.description || "Emergency assistance requested").slice(0, 1000);

  if (!ALLOWED_CATEGORIES.has(category)) return Response.json({ error: "Invalid safety category" }, { status: 400 });
  if (!ALLOWED_SEVERITIES.has(severity)) return Response.json({ error: "Invalid severity" }, { status: 400 });

  if (category === "SOS") {
    const { data: incident, error } = await supabase.rpc("create_sos_incident", {
      p_job_id: jobId,
      p_description: description
    });
    if (error) return Response.json({ error: error.message }, { status: 400 });
    return Response.json({ incident });
  }

  const { data: incident, error } = await supabase
    .from("safety_incidents")
    .insert({
      job_id: jobId,
      reporter_id: user.id,
      category,
      description,
      severity,
      status: "open"
    })
    .select()
    .single();

  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json({ incident });
}
