import { createClient } from "@/lib/supabase/server";

export async function GET() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const { data: me } = await supabase.from("profiles").select("role").eq("id", user.id).maybeSingle();
  if (!["ADMIN","DISPATCHER"].includes(me?.role || "")) return Response.json({ error: "Forbidden" }, { status: 403 });

  const { data, error } = await supabase.from("identity_verifications")
    .select("id,user_id,subject_type,gender,status,document_type,verified_at,rejection_reason,created_at,profiles:user_id(full_name,phone,avatar_url)")
    .order("created_at", { ascending: false }).limit(100);

  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json({ verifications: data || [] });
}
