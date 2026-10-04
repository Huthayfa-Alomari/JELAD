import { createClient } from "@/lib/supabase/server";

export async function POST(req:Request,{params}:{params:Promise<{id:string}>}) {
 const supabase=await createClient(); const {data:{user}}=await supabase.auth.getUser();
 if(!user)return Response.json({error:"Authentication required"},{status:401});
 const {id}=await params; const body=await req.json(); const action=String(body.action||"");
 if(!["ARRIVED","START","COMPLETE"].includes(action))return Response.json({error:"Invalid action"},{status:400});
 const {data,error}=await supabase.rpc("driver_job_transition",{p_job_id:id,p_action:action});
 if(error)return Response.json({error:error.message},{status:400}); return Response.json({job:data});
}