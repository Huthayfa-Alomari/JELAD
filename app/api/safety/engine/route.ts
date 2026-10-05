import { createClient } from "@/lib/supabase/server";

const ACTIONS = new Set(["crash","deviation","tamper"]);

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const b = await req.json().catch(() => ({}));
  const action = String(b.action || "").toLowerCase();
  if (!ACTIONS.has(action)) return Response.json({ error: "Invalid safety engine action" }, { status: 400 });

  if (action === "crash") {
    const impactG = Number(b.impactG);
    if (!Number.isFinite(impactG) || impactG < 0 || impactG > 100) return Response.json({ error: "Invalid impactG" }, { status: 400 });
    const { data, error } = await supabase.rpc("record_crash_event", {
      p_job_id: b.jobId ? String(b.jobId) : null,
      p_vehicle_id: String(b.vehicleId || ""),
      p_driver_id: user.id,
      p_impact_g: impactG,
      p_lat: b.latitude == null ? null : Number(b.latitude),
      p_lng: b.longitude == null ? null : Number(b.longitude),
      p_metadata: b.metadata || {}
    });
    if (error) return Response.json({ error: error.message }, { status: 400 });
    return Response.json({ crashEventId: data, autoSos: impactG >= 2.5 });
  }

  if (action === "deviation") {
    const meters = Number(b.deviationMeters);
    const seconds = Number(b.durationSeconds);
    if (!Number.isFinite(meters) || !Number.isFinite(seconds) || meters < 0 || seconds < 0) return Response.json({ error: "Invalid deviation values" }, { status: 400 });
    const { data, error } = await supabase.rpc("record_route_deviation", {
      p_job_id: String(b.jobId || ""),
      p_vehicle_id: String(b.vehicleId || ""),
      p_driver_id: user.id,
      p_deviation_meters: meters,
      p_duration_seconds: Math.floor(seconds),
      p_lat: b.latitude == null ? null : Number(b.latitude),
      p_lng: b.longitude == null ? null : Number(b.longitude),
      p_metadata: b.metadata || {}
    });
    if (error) return Response.json({ error: error.message }, { status: 400 });
    return Response.json({ eventId: data, triggered: Boolean(data) });
  }

  const { data, error } = await supabase.rpc("record_device_tamper", {
    p_device_id: String(b.deviceId || ""),
    p_vehicle_id: String(b.vehicleId || ""),
    p_job_id: b.jobId ? String(b.jobId) : null,
    p_tamper_type: String(b.tamperType || "OTHER"),
    p_lat: b.latitude == null ? null : Number(b.latitude),
    p_lng: b.longitude == null ? null : Number(b.longitude),
    p_metadata: b.metadata || {}
  });
  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json({ tamperEventId: data });
}
