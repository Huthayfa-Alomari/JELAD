import { createClient } from "@/lib/supabase/server";

const MAX_BYTES = 8 * 1024 * 1024;
const rules = {
  document: new Set(["image/jpeg","image/png","image/webp","application/pdf"]),
  selfie: new Set(["image/jpeg","image/png","image/webp"]),
} as const;

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const form = await req.formData();
  const kind = form.get("kind") === "selfie" ? "selfie" : "document";
  const file = form.get("file");
  if (!(file instanceof File)) return Response.json({ error: "File is required" }, { status: 400 });
  if (file.size <= 0 || file.size > MAX_BYTES) return Response.json({ error: "File must be between 1 byte and 8 MB" }, { status: 413 });
  if (!rules[kind].has(file.type as never)) return Response.json({ error: "Unsupported file type" }, { status: 415 });

  const ext = file.name.split(".").pop()?.toLowerCase().replace(/[^a-z0-9]/g, "") || (file.type === "application/pdf" ? "pdf" : "jpg");
  const path = user.id + "/" + crypto.randomUUID() + "/" + kind + "." + ext;
  const bytes = new Uint8Array(await file.arrayBuffer());

  const { error } = await supabase.storage.from("identity-documents").upload(path, bytes, {
    contentType: file.type,
    cacheControl: "3600",
    upsert: false,
  });
  if (error) return Response.json({ error: "Secure upload failed" }, { status: 400 });

  await supabase.from("audit_events").insert({
    actor_id: user.id,
    entity_type: "IDENTITY_DOCUMENT",
    action: "UPLOAD_" + kind.toUpperCase(),
  });

  return Response.json({ path, kind });
}