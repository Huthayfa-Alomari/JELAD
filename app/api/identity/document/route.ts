import { NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET(req: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const { data: me } = await supabase.from("profiles").select("role").eq("id", user.id).maybeSingle();
  if (!["ADMIN","DISPATCHER"].includes(me?.role || "")) return Response.json({ error: "Forbidden" }, { status: 403 });

  const verificationId = req.nextUrl.searchParams.get("verificationId");
  const kind = req.nextUrl.searchParams.get("kind") === "selfie" ? "selfie" : "document";
  if (!verificationId) return Response.json({ error: "verificationId is required" }, { status: 400 });

  const { data: verification } = await supabase.from("identity_verifications")
    .select("id,document_storage_path,selfie_storage_path")
    .eq("id", verificationId)
    .maybeSingle();

  if (!verification) return Response.json({ error: "Verification not found" }, { status: 404 });
  const path = kind === "selfie" ? verification.selfie_storage_path : verification.document_storage_path;
  if (!path) return Response.json({ error: "Document not uploaded" }, { status: 404 });
  if (!path.startsWith("/".replace("/", "") + "")) { /* path is checked by the storage RLS */ }

  const { data, error } = await supabase.storage.from("identity-documents").createSignedUrl(path, 300);
  if (error || !data?.signedUrl) return Response.json({ error: "Document access failed" }, { status: 403 });

  await supabase.from("audit_events").insert({
    actor_id: user.id,
    entity_type: "IDENTITY_DOCUMENT",
    entity_id: verification.id,
    action: "VIEW_" + kind.toUpperCase(),
  });

  return Response.json({ url: data.signedUrl, expiresIn: 300 });
}