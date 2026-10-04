"use client";
import { FormEvent, useState } from "react";
import { createClient } from "@/lib/supabase/client";

export default function LoginPage(){
 const supabase=createClient();
 const [phone,setPhone]=useState("");
 const [otp,setOtp]=useState("");
 const [sent,setSent]=useState(false);
 const [loading,setLoading]=useState(false);
 const [message,setMessage]=useState("");
 async function send(e:FormEvent){e.preventDefault();setLoading(true);setMessage("");
  const {error}=await supabase.auth.signInWithOtp({phone:phone.trim()});
  setLoading(false); if(error){setMessage(error.message);return;} setSent(true);setMessage("Verification code sent.");
 }
 async function verify(e:FormEvent){e.preventDefault();setLoading(true);setMessage("");
  const {error}=await supabase.auth.verifyOtp({phone:phone.trim(),token:otp.trim(),type:"sms"});
  setLoading(false); if(error){setMessage(error.message);return;} window.location.href="/";
 }
 return <main className="min-h-screen bg-[#f7f8fa] p-5"><div className="mx-auto flex min-h-[calc(100vh-40px)] max-w-md items-center">
  <div className="w-full rounded-[32px] bg-white p-7 shadow-sm ring-1 ring-[#eaecf0]">
   <a href="/" className="text-sm text-[#667085]">← JELAD</a>
   <p className="mt-10 text-xs font-semibold uppercase tracking-[.18em] text-[#c89252]">Secure access</p>
   <h1 className="mt-2 text-3xl font-semibold tracking-[-.03em]">Welcome back</h1>
   <p className="mt-2 text-sm leading-6 text-[#667085]">Sign in with your Jordanian mobile number.</p>
   <form onSubmit={sent?verify:send} className="mt-7 space-y-4">
    <label className="block"><span className="text-sm font-medium">Mobile number</span><input required type="tel" inputMode="tel" value={phone} onChange={e=>setPhone(e.target.value)} placeholder="+962 7X XXX XXXX" disabled={sent} className="mt-2 w-full rounded-2xl border border-[#eaecf0] px-4 py-3.5 outline-none focus:border-[#182230]"/></label>
    {sent&&<label className="block"><span className="text-sm font-medium">Verification code</span><input required inputMode="numeric" value={otp} onChange={e=>setOtp(e.target.value)} placeholder="6-digit code" className="mt-2 w-full rounded-2xl border border-[#eaecf0] px-4 py-3.5 outline-none focus:border-[#182230]"/></label>}
    <button disabled={loading} className="w-full rounded-2xl bg-[#182230] py-4 text-sm font-semibold text-white disabled:opacity-60">{loading?"Please wait…":sent?"Verify & continue":"Send verification code"}</button>
   </form>
   {message&&<p className="mt-4 rounded-2xl bg-[#f7f8fa] p-3 text-sm text-[#667085]">{message}</p>}
  </div>
 </div></main>
}