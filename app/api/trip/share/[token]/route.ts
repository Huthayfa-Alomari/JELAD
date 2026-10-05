import { NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET(_req:NextRequest,{params}:{params:Promise<{token:string}>}) {
  const {token}=await params;
  const supabase=await createClient();
  const {data,error}=await supabase.rpc("get_public_trip_tracking",{p_share_token:token});
  if(error) return Response.json({error:"Tracking unavailable"},{status:404});
  if(!data) return Response.json({error:"Trip not found"},{status:404});
  return Response.json({trip:data},{headers:{"cache-control":"no-store"}});
}
