import { createHmac, timingSafeEqual } from "node:crypto";
import { createClient } from "@supabase/supabase-js";

function validSignature(raw: string, signature: string | null, key: string) {
  if (!signature) return false;
  const expected = createHmac("sha256", key).update(raw).digest("hex");
  const a = Buffer.from(expected, "utf8");
  const b = Buffer.from(signature, "utf8");
  return a.length === b.length && timingSafeEqual(a, b);
}

export async function POST(req: Request) {
  const serverKey = process.env.PAYTABS_SERVER_KEY;
  if (!serverKey) return Response.json({ error: "PayTabs is not configured" }, { status: 503 });

  const raw = await req.text();
  if (!validSignature(raw, req.headers.get("signature"), serverKey)) {
    return Response.json({ error: "Invalid signature" }, { status: 401 });
  }

  let payload: Record<string, unknown>;
  try {
    payload = JSON.parse(raw);
  } catch {
    return Response.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const tranRef = String(payload.tran_ref || "");
  const responseStatus = String(
    (payload.payment_result as Record<string, unknown> | undefined)?.response_status ||
    payload.response_status || ""
  ).toUpperCase();

  if (!tranRef) return Response.json({ error: "Missing transaction reference" }, { status: 400 });

  const status = responseStatus === "A" ? "PAID" : "FAILED";
  const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!);

  const { error } = await supabase
    .from("payments")
    .update({ status, provider_reference: tranRef })
    .eq("provider", "PAYTABS")
    .eq("provider_reference", tranRef);

  if (error) return Response.json({ error: "Payment status update failed" }, { status: 500 });

  return Response.json({ ok: true });
}
