import { NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const [{ data: profile }, { data: driver }, { data: verifications }] = await Promise.all([
    supabase.from("profiles").select("id,gender,identity_verified,identity_verified_at,identity_verified_gender,female_safety_enabled").eq("id", user.id).maybeSingle(),
    supabase.from("drivers").select("id,gender,identity_verified,identity_verified_at,identity_verified_gender,is_female_driver,accepts_women_only").eq("id", user.id).maybeSingle(),
    supabase.from("identity_verifications").select("id,subject_type,gender,status,document_type,verified_at,rejection_reason,created_at").eq("user_id", user.id)
  ]);

  return Response.json({ profile, driver, verifications: verifications || [] });
}

export async function POST(req: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const body = await req.json();
  const documentStoragePath = String(body.documentStoragePath || "");
  const selfieStoragePath = String(body.selfieStoragePath || "");
  if (!documentStoragePath.startsWith(user.id + "/") || !selfieStoragePath.startsWith(user.id + "/")) return Response.json({ error: "Secure identity uploads are required" }, { status: 400 });
  const subjectType = body.subjectType === "DRIVER" ? "DRIVER" : "CUSTOMER";
  const gender = body.gender === "female" ? "female" : body.gender === "male" ? "male" : null;
  if (!gender) return Response.json({ error: "Gender is required for identity verification" }, { status: 400 });

  const { data, error } = await supabase.from("identity_verifications").upsert({
    user_id: user.id,
    subject_type: subjectType,
    gender,
    status: "PENDING",
    document_type: body.documentType || null,
    document_storage_path: body.documentStoragePath || null,
    selfie_storage_path: body.selfieStoragePath || null,
    verified_at: null,
    verified_by: null,
    rejection_reason: null,
    updated_at: new Date().toISOString()
  }, { onConflict: "user_id,subject_type" }).select().single();

  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json({ verification: data, message: "Identity verification submitted for review." });
}
