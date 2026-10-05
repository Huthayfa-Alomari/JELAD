import {createClient} from "@/lib/supabase/server";
export async function POST(req:Request){
 const supabase=await createClient();const {data:{user}}=await supabase.auth.getUser();if(!user)return Response.json({error:"Authentication required"},{status:401});
 const b=await req.json();const jobId=b.jobId?String(b.jobId):null;const category=String(b.category||"SOS");const description=String(b.description||"Emergency assistance requested");
 if(category==="SOS"&&jobId){const {data,error}=await supabase.rpc("create_sos_incident",{p_job_id:jobId,p_description:description});if(error)return Response.json({error:error.message},{status:400});return Response.json({incident:data});}
 const {data,error}=await supabase.from("safety_incidents").insert({job_id:jobId,reporter_id:user.id,category,description,severity:String(b.severity||"high"),status:"open"}).select().single();
 if(error)return Response.json({error:error.message},{status:400});return Response.json({incident:data});
}