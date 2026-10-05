import { createClient } from "@/lib/supabase/server";

export async function GET() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const { data: isOps } = await supabase.rpc("is_ops_user");
  if (!isOps) return Response.json({ error: "Operations access required" }, { status: 403 });

  const { data: count, error } = await supabase.rpc("detect_stale_devices");
  if (error) return Response.json({ error: "Safety health check unavailable" }, { status: 500 });
  return Response.json({ staleDevicesDetected: count || 0, checkedAt: new Date().toISOString() });
}
