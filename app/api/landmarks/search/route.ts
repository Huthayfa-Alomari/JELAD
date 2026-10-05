import { NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET(req:NextRequest) {
  const q=(new URL(req.url).searchParams.get("q")||"").trim();
  const city=(new URL(req.url).searchParams.get("city")||"").trim();
  if(q.length<2) return Response.json({landmarks:[]});
  const supabase=await createClient();
  let query=supabase.from("landmarks").select("*").or(`name_ar.ilike.%${q}%,name_en.ilike.%${q}%`).limit(12);
  if(city) query=query.eq("city",city);
  const {data,error}=await query;
  if(error) return Response.json({error:error.message},{status:400});
  return Response.json({landmarks:data||[]});
}
