import { NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(req:NextRequest) {
  const supabase=await createClient();
  const {data:{user}}=await supabase.auth.getUser();
  if(!user) return Response.json({error:"Authentication required"},{status:401});
  const body=await req.json().catch(()=>({}));
  const amount=Number(body.amount);
  const payoutMethod=String(body.payoutMethod||"");
  const accountNumber=String(body.accountNumber||"").trim();
  if(!Number.isFinite(amount)||amount<=0||!["ZAIN_CASH","ORANGE_MONEY","BANK"].includes(payoutMethod)||!accountNumber) return Response.json({error:"Invalid payout request"},{status:400});
  const {data:driver}=await supabase.from("drivers").select("id").eq("id",user.id).single();
  if(!driver) return Response.json({error:"Driver profile not found"},{status:403});
  const {data:entries,error:ledgerError}=await supabase.from("wallet_ledger").select("amount,direction").eq("user_id",user.id);
  if(ledgerError) return Response.json({error:ledgerError.message},{status:400});
  const balance=(entries||[]).reduce((s,e)=>s+(e.direction==="CREDIT"?Number(e.amount):-Number(e.amount)),0);
  if(amount>balance) return Response.json({error:"Insufficient wallet balance"},{status:409});
  const {data,error}=await supabase.from("driver_payouts").insert({driver_id:user.id,amount,payout_method:payoutMethod,account_number:accountNumber}).select().single();
  if(error) return Response.json({error:error.message},{status:400});
  return Response.json({payout:data,status:"PENDING"});
}
