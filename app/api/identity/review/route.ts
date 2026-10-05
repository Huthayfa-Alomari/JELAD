import { NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(req: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const { data: me } = await supabase.from("profiles").select("role").eq("id", user.id).maybeSingle();
  if (!["ADMIN","DISPATCHER"].includes(me?.role || "")) return Response.json({ error: "Forbidden" }, { status: 403 });

  const body = await req.json();
  const status = ["VERIFIED","REJECTED","PENDING"].includes(body.status) ? body.status : null;
  if (!status || !body.verificationId) return Response.json({ error: "verificationId and valid status are required" }, { status: 400 });

  const { data: verification, error } = await supabase.from("identity_verifications")
    .update({
      status,
      verified_at: status === "VERIFIED" ? new Date().toISOString() : null,
      verified_by: status === "VERIFIED" ? user.id : null,
      rejection_reason: status === "REJECTED" ? String(body.rejectionReason || "Identity verification rejected") : null,
      updated_at: new Date().toISOString()
    })
    .eq("id", body.verificationId)
    .select().single();

  if (error || !verification) return Response.json({ error: error?.message || "Verification not found" }, { status: 400 });

  if (verification.subject_type === "DRIVER") {
    await supabase.from("drivers").update({
      identity_verified: status === "VERIFIED",
      identity_verified_at: status === "VERIFIED" ? new Date().toISOString() : null,
      identity_verified_gender: status === "VERIFIED" ? verification.gender : null,
      is_female_driver: verification.gender === "female" && status === "VERIFIED"
    }).eq("id", verification.user_id);
  } else {
    await supabase.from("profiles").update({
      identity_verified: status === "VERIFIED",
      identity_verified_at: status === "VERIFIED" ? new Date().toISOString() : null,
      female_safety_enabled: verification.gender === "female" && status === "VERIFIED"
    }).eq("id", verification.user_id);
  }

  return Response.json({ verification });
}
