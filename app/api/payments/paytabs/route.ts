import { createClient as createServerClient } from "@/lib/supabase/server";
import { createClient as createSupabaseClient } from "@supabase/supabase-js";

export async function POST(req: Request) {
  const authorization = req.headers.get("authorization");
  const supabase = authorization?.toLowerCase().startsWith("bearer ")
    ? createSupabaseClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
        { global: { headers: { Authorization: authorization } } },
      )
    : await createServerClient();

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const body = await req.json();
  const jobId = String(body.jobId || "");
  if (!jobId) return Response.json({ error: "jobId is required" }, { status: 400 });

  const { data: job, error: jobError } = await supabase
    .from("jobs")
    .select("id,customer_id,type,estimated_amount,final_amount,status")
    .eq("id", jobId)
    .eq("customer_id", user.id)
    .single();

  if (jobError || !job) return Response.json({ error: "Job not found" }, { status: 404 });
  if (["CANCELLED","COMPLETED"].includes(job.status)) {
    return Response.json({ error: "Payment cannot be started for this job state" }, { status: 409 });
  }

  const amount = Number(job.final_amount ?? job.estimated_amount ?? 0);
  if (!Number.isFinite(amount) || amount <= 0) return Response.json({ error: "Invalid job amount" }, { status: 400 });

  const profileId = process.env.PAYTABS_PROFILE_ID;
  const serverKey = process.env.PAYTABS_SERVER_KEY;
  const appUrl = process.env.NEXT_PUBLIC_APP_URL;
  const endpoint = process.env.PAYTABS_ENDPOINT || "https://secure-jordan.paytabs.com/payment/request";

  if (!profileId || !serverKey || !appUrl) {
    return Response.json({ error: "PayTabs is not configured" }, { status: 503 });
  }

  const { data: payment, error: paymentError } = await supabase.rpc("create_payment", {
    p_job_id: job.id,
    p_amount: amount,
    p_provider: "PAYTABS",
  });
  if (paymentError || !payment) {
    return Response.json({ error: paymentError?.message || "Unable to create payment" }, { status: 400 });
  }

  const paymentRow = Array.isArray(payment) ? payment[0] : payment;
  const paymentId = paymentRow?.id;
  const cartId = `JELAD-${paymentId}`;

  const response = await fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: serverKey },
    body: JSON.stringify({
      profile_id: Number(profileId),
      tran_type: "sale",
      tran_class: "ecom",
      cart_id: cartId,
      cart_currency: "JOD",
      cart_amount: amount,
      cart_description: `JELAD ${job.type} ${job.id}`,
      return: `${appUrl}/payment/return?jobId=${job.id}`,
      callback: `${appUrl}/api/payments/paytabs/callback`,
    }),
  });

  const result = await response.json().catch(() => ({}));
  if (!response.ok || !result.redirect_url) {
    return Response.json({ error: "PayTabs payment initiation failed", details: result }, { status: 502 });
  }

  const { error: refError } = await supabase
    .from("payments")
    .update({ provider_reference: result.tran_ref })
    .eq("id", paymentId)
    .eq("customer_id", user.id);

  if (refError) return Response.json({ error: "Payment created but reference could not be saved" }, { status: 500 });

  return Response.json({ paymentId, tranRef: result.tran_ref, redirectUrl: result.redirect_url });
}
