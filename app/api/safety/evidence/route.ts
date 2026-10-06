import crypto from "node:crypto";
import { createClient } from "@/lib/supabase/server";

const MAX_BYTES = 512 * 1024 * 1024;
const ALLOWED = new Set(["video/mp4","video/webm","image/jpeg","image/png"]);
const CAMERAS = new Set(["FRONT","INTERIOR","REAR","OTHER"]);

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error:"Authentication required" },{status:401});

  const form = await req.formData().catch(() => null);
  if (!form) return Response.json({error:"multipart/form-data required"},{status:400});
  const file = form.get("file");
  const jobId = String(form.get("jobId")||"");
  const vehicleId = String(form.get("vehicleId")||"");
  const deviceId = String(form.get("deviceId")||"");
  const safetyEventId = String(form.get("safetyEventId")||"") || null;
  const cameraType = String(form.get("cameraType")||"OTHER").toUpperCase();
  const capturedAt = String(form.get("capturedAt")||new Date().toISOString());
  const durationSeconds = Math.max(0,Math.min(3600,Number(form.get("durationSeconds")||0)));

  if (!(file instanceof File) || !jobId || !vehicleId || !deviceId || !CAMERAS.has(cameraType))
    return Response.json({error:"file, jobId, vehicleId, deviceId and cameraType are required"},{status:400});
  if (file.size <= 0 || file.size > MAX_BYTES || !ALLOWED.has(file.type))
    return Response.json({error:"Unsupported or oversized evidence file"},{status:400});

  const { data: vehicle } = await supabase.from("vehicles").select("id,driver_id").eq("id",vehicleId).maybeSingle();
  const { data: job } = await supabase.from("jobs").select("id,driver_id,status").eq("id",jobId).maybeSingle();
  const { data: device } = await supabase.from("vehicle_devices").select("id,vehicle_id,status").eq("id",deviceId).maybeSingle();
  if (!vehicle || vehicle.driver_id !== user.id || !job || job.driver_id !== user.id ||
      !["ASSIGNED","DRIVER_ARRIVING","IN_PROGRESS"].includes(job.status) ||
      !device || device.vehicle_id !== vehicleId || !["ACTIVE","TAMPERED"].includes(device.status))
    return Response.json({error:"Evidence source is not authorized for this trip"},{status:403});

  const bytes = new Uint8Array(await file.arrayBuffer());
  const sha256 = crypto.createHash("sha256").update(bytes).digest("hex");
  const ext = file.type==="video/mp4"?"mp4":file.type==="video/webm"?"webm":file.type==="image/png"?"png":"jpg";
  const storagePath = `driver/${user.id}/${vehicleId}/${jobId}/${crypto.randomUUID()}.${ext}`;
  const { error: uploadError } = await supabase.storage.from("safety-evidence").upload(storagePath,bytes,{
    contentType:file.type, upsert:false, cacheControl:"0"
  });
  if (uploadError) return Response.json({error:uploadError.message},{status:400});

  const { data: evidence, error } = await supabase.from("camera_evidence").insert({
    safety_event_id:safetyEventId, job_id:jobId, vehicle_id:vehicleId, device_id:deviceId,
    camera_type:cameraType, storage_path:storagePath, media_type:file.type,
    captured_at:new Date(capturedAt).toISOString(), duration_seconds:durationSeconds,
    sha256, encrypted:true, access_class:"SAFETY_EVENT"
  }).select("id,job_id,vehicle_id,device_id,camera_type,media_type,captured_at,sha256,encrypted").single();

  if (error) {
    await supabase.storage.from("safety-evidence").remove([storagePath]);
    return Response.json({error:error.message},{status:400});
  }

  await supabase.from("audit_events").insert({
    actor_id:user.id, entity_type:"CAMERA_EVIDENCE", entity_id:evidence.id,
    action:"EVIDENCE_UPLOADED", metadata:{job_id:jobId,vehicle_id:vehicleId,device_id:deviceId,camera_type:cameraType,sha256}
  });
  return Response.json({evidence}, {status:201});
}

export async function GET(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });
  const { data: isOps } = await supabase.rpc("is_ops_user");
  if (!isOps) return Response.json({ error: "Operations access required" }, { status: 403 });
  const evidenceId = new URL(req.url).searchParams.get("evidenceId");
  const purpose = (new URL(req.url).searchParams.get("purpose") || "SAFETY_REVIEW").slice(0,120);
  if (!evidenceId) return Response.json({error:"evidenceId is required"},{status:400});
  const {data:evidence,error}=await supabase.from("camera_evidence").select("id,storage_path,media_type,camera_type,captured_at,job_id,vehicle_id,access_class,deleted_at").eq("id",evidenceId).maybeSingle();
  if(error)return Response.json({error:error.message},{status:400});
  if(!evidence||evidence.deleted_at)return Response.json({error:"Evidence unavailable"},{status:404});
  const {data:signed,error:signedError}=await supabase.storage.from("safety-evidence").createSignedUrl(evidence.storage_path,300);
  if(signedError||!signed?.signedUrl)return Response.json({error:signedError?.message||"Unable to sign evidence"},{status:400});
  const forwarded=req.headers.get("x-forwarded-for")||"";
  const ipHash=crypto.createHash("sha256").update(forwarded).digest("hex");
  const {error:logError}=await supabase.from("evidence_access_logs").insert({evidence_id:evidence.id,accessed_by:user.id,purpose,ip_hash:ipHash,metadata:{expires_in_seconds:300,camera_type:evidence.camera_type}});
  if(logError)return Response.json({error:"Evidence access could not be audited"},{status:500});
  return Response.json({evidence:{...evidence,signedUrl:signed.signedUrl,expiresIn:300}});
}