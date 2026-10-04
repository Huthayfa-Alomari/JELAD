import { createClient } from "@/lib/supabase/server";
export async function POST(req:Request,{params}:{params:Promise<{id:string}>}) {
 const supabase=await createClient(); const {data:{user}}=await supabase.auth.getUser();
 if(!user)return Response.json({error:"Authentication required"},{status:401});
 const {id}=await params; const body=await req.json().catch(()=>({}));
 const {data,error}=await supabase.rpc("cancel_customer_job",{p_job_id:id,p_reason:String(body.reason||"Customer cancelled")});
 if(error)return Response.json({error:error.message},{status:400}); return Response.json({job:data});
}