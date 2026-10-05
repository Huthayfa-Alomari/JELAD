import { createClient } from "@/lib/supabase/server";
export async function POST(req:Request){
 const supabase=await createClient();const {data:{user}}=await supabase.auth.getUser();
 if(!user)return Response.json({error:"Authentication required"},{status:401});
 const b=await req.json();const lat=Number(b.lat),lng=Number(b.lng);
 if(!Number.isFinite(lat)||!Number.isFinite(lng))return Response.json({error:"Invalid coordinates"},{status:400});
 const {data,error}=await supabase.rpc("update_driver_location",{p_lat:lat,p_lng:lng});
 if(error)return Response.json({error:error.message},{status:400});
 const {data:jobs}=await supabase.from("jobs").select("id,share_token").eq("driver_id",user.id).in("status",["ASSIGNED","DRIVER_ARRIVING","IN_PROGRESS"]);
 for(const job of jobs||[]){
   await supabase.from("trip_live_locations").upsert({job_id:job.id,share_token:job.share_token,latitude:lat,longitude:lng,updated_at:new Date().toISOString()});
 }
 return Response.json({driver:data});
}