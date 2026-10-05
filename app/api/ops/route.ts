import { createClient } from "@/lib/supabase/server";

export async function GET() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const { data: isOps, error: roleError } = await supabase.rpc("is_ops_user");
  if (roleError || !isOps) return Response.json({ error: "Operations access required" }, { status: 403 });

  const [{ data: jobs, error: je }, { data: drivers, error: de }, { data: incidents, error: ie }, { data: safetyEvents, error: se }, { data: devices, error: de2 }, { data: tamper, error: te }, { data: crashes, error: ce }, { data: deviations, error: re }] = await Promise.all([
    supabase.from("jobs").select("*,pickup:pickup_location_id(*),destination:destination_location_id(*)").order("created_at", { ascending: false }).limit(100),
    supabase.from("drivers").select("*").order("updated_at", { ascending: false }).limit(100),
    supabase.from("safety_incidents").select("*").order("created_at", { ascending: false }).limit(30),
    supabase.from("safety_events").select("*").order("occurred_at", { ascending: false }).limit(50),
    supabase.from("vehicle_devices").select("*").order("updated_at", { ascending: false }).limit(100),
    supabase.from("device_tamper_events").select("*").order("detected_at", { ascending: false }).limit(20),
    supabase.from("crash_events").select("*").order("detected_at", { ascending: false }).limit(20),
    supabase.from("route_deviation_events").select("*").order("detected_at", { ascending: false }).limit(20)
  ]);

  const firstError = je || de || ie || se || de2 || te || ce || re;
  if (firstError) return Response.json({ error: firstError.message }, { status: 500 });

  return Response.json({ jobs, drivers, incidents, safetyEvents, devices, tamper, crashes, deviations });
}
