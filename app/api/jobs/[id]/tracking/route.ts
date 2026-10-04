import { createClient } from "@/lib/supabase/server";

export async function GET(_: Request, { params }: { params: Promise<{ id: string }> }) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });
  const { id } = await params;
  const { data, error } = await supabase.rpc("get_customer_job_tracking", { p_job_id: id });
  if (error) return Response.json({ error: error.message }, { status: 404 });
  return Response.json(data);
}
