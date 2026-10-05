import { createClient } from "@/lib/supabase/server";

function normalizePhone(value: unknown) {
  const raw = String(value || "").trim().replace(/[\s()-]/g, "");
  if (/^07\d{8}$/.test(raw)) return "+962" + raw.slice(1);
  if (/^9627\d{8}$/.test(raw)) return "+" + raw;
  if (/^\+9627\d{8}$/.test(raw)) return raw;
  return null;
}

export async function GET() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const { data, error } = await supabase.from("trusted_contacts")
    .select("id,contact_name,contact_phone,relationship,is_verified,created_at,updated_at")
    .order("created_at", { ascending: true });
  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json({ contacts: data || [] });
}

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const body = await req.json().catch(() => ({}));
  const name = String(body.contactName || "").trim().slice(0, 80);
  const phone = normalizePhone(body.contactPhone);
  const relationship = String(body.relationship || "").trim().slice(0, 40) || null;
  if (!name || !phone) return Response.json({ error: "اسم ورقم هاتف أردني صالحان مطلوبان" }, { status: 400 });

  const { data, error } = await supabase.from("trusted_contacts").insert({
    user_id: user.id,
    contact_name: name,
    contact_phone: phone,
    relationship,
    is_verified: false
  }).select("id,contact_name,contact_phone,relationship,is_verified,created_at").single();

  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json({ contact: data }, { status: 201 });
}

export async function DELETE(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });
  const id = new URL(req.url).searchParams.get("id");
  if (!id) return Response.json({ error: "id is required" }, { status: 400 });

  const { error } = await supabase.from("trusted_contacts").delete().eq("id", id);
  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json({ ok: true });
}
