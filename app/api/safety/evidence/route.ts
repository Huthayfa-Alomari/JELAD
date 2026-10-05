import crypto from "node:crypto";
import { createClient } from "@/lib/supabase/server";

export async function GET(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const { data: isOps } = await supabase.rpc("is_ops_user");
  if (!isOps) return Response.json({ error: "Operations access required" }, { status: 403 });

  const url = new URL(req.url);
  const evidenceId = url.searchParams.get("evidenceId");
  const purpose = (url.searchParams.get("purpose") || "SAFETY_REVIEW").slice(0, 120);
  if (!evidenceId) return Response.json({ error: "evidenceId is required" }, { status: 400 });

  const { data: evidence, error } = await supabase
    .from("camera_evidence")
    .select("id,storage_path,media_type,camera_type,captured_at,job_id,vehicle_id,access_class,deleted_at")
    .eq("id", evidenceId)
    .maybeSingle();

  if (error) return Response.json({ error: error.message }, { status: 400 });
  if (!evidence || evidence.deleted_at) return Response.json({ error: "Evidence unavailable" }, { status: 404 });

  const { data: signed, error: signedError } = await supabase.storage
    .from("safety-evidence")
    .createSignedUrl(evidence.storage_path, 300);

  if (signedError || !signed?.signedUrl) {
    return Response.json({ error: signedError?.message || "Unable to sign evidence" }, { status: 400 });
  }

  const forwarded = req.headers.get("x-forwarded-for") || "";
  const ipHash = crypto.createHash("sha256").update(forwarded).digest("hex");

  const { error: logError } = await supabase.from("evidence_access_logs").insert({
    evidence_id: evidence.id,
    accessed_by: user.id,
    purpose,
    ip_hash: ipHash,
    metadata: { expires_in_seconds: 300, camera_type: evidence.camera_type }
  });

  if (logError) return Response.json({ error: "Evidence access could not be audited" }, { status: 500 });

  return Response.json({
    evidence: { ...evidence, signedUrl: signed.signedUrl, expiresIn: 300 }
  });
}
