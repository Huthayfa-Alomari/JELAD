import { NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(req: NextRequest) {
  const supabase = await createClient();
  const { data:{user} } = await supabase.auth.getUser();
  if (!user) return Response.json({error:"Authentication required"},{status:401});
  const body = await req.json().catch(()=>({}));
  const jobId = String(body.jobId||"").trim();
  const pin = String(body.pin||"").trim();
  if (!jobId || !/^\d{4}$/.test(pin)) return Response.json({error:"A valid 4-digit PIN is required"},{status:400});
  const {data,error}=await supabase.rpc("verify_trip_start_pin",{p_job_id:jobId,p_pin:pin});
  if(error) return Response.json({error:error.message},{status:400});
  return Response.json({job:Array.isArray(data)?data[0]:data});
}
