import { createClient } from "@/lib/supabase/server";

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const b = await req.json().catch(() => ({}));
  const deviceId = String(b.deviceId || "");
  const vehicleId = String(b.vehicleId || "");
  const jobId = b.jobId ? String(b.jobId) : null;
  const latitude = Number(b.latitude);
  const longitude = Number(b.longitude);

  if (!deviceId || !vehicleId || !Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    return Response.json({ error: "deviceId, vehicleId, latitude and longitude are required" }, { status: 400 });
  }
  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    return Response.json({ error: "Invalid coordinates" }, { status: 400 });
  }

  const { data: driver } = await supabase.from("drivers").select("id").eq("id", user.id).maybeSingle();
  if (!driver) return Response.json({ error: "Driver account required" }, { status: 403 });

  const { data, error } = await supabase.rpc("record_device_telemetry", {
    p_device_id: deviceId,
    p_vehicle_id: vehicleId,
    p_job_id: jobId,
    p_lat: latitude,
    p_lng: longitude,
    p_speed: b.speedKmh == null ? null : Number(b.speedKmh),
    p_heading: b.heading == null ? null : Number(b.heading),
    p_accuracy: b.accuracyM == null ? null : Number(b.accuracyM),
    p_battery: b.batteryPercent == null ? null : Number(b.batteryPercent),
    p_ignition: b.ignitionOn == null ? null : Boolean(b.ignitionOn),
    p_motion: b.motionDetected == null ? null : Boolean(b.motionDetected)
  });

  if (error) return Response.json({ error: error.message }, { status: 400 });

  const speed = Number(b.speedKmh || 0);
  if (speed >= 120) {
    await supabase.from("safety_events").insert({
      job_id: jobId,
      vehicle_id: vehicleId,
      driver_id: user.id,
      event_type: "SPEED_ALERT",
      severity: speed >= 150 ? "CRITICAL" : "HIGH",
      latitude,
      longitude,
      metadata: { speed_kmh: speed, source: "telemetry" }
    });
  }

  return Response.json({ telemetryId: data });
}
