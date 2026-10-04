"use client";
import { useState } from "react";
export function RequestButton({destinationAddress,rideClass}:{destinationAddress:string;rideClass:string}){
 const [loading,setLoading]=useState(false),[message,setMessage]=useState("");
 async function request(){
  setLoading(true);setMessage("");
  if(!destinationAddress.trim()){setMessage("Enter a destination first.");setLoading(false);return;}
  if(!navigator.geolocation){setMessage("Location access is required.");setLoading(false);return;}
  navigator.geolocation.getCurrentPosition(async p=>{
   try{
    const r=await fetch("/api/jobs",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({type:"RIDE",destinationAddress,rideClass,pickupLat:p.coords.latitude,pickupLng:p.coords.longitude})});
    const data=await r.json(); if(!r.ok)throw new Error(data.error||"Could not create ride");
    setMessage(`Ride requested · ${data.distanceKm} km · ${Number(data.estimate).toFixed(2)} JOD`);
   }catch(e){setMessage(e instanceof Error?e.message:"Request failed");}finally{setLoading(false);}
  },()=>{setMessage("Please allow location access to request a ride.");setLoading(false)},{enableHighAccuracy:true,timeout:10000});
 }
 return <div className="mt-5"><button onClick={request} disabled={loading} className="w-full rounded-2xl bg-[#182230] py-4 text-sm font-semibold text-white disabled:opacity-60">{loading?"Finding route…":"Confirm ride"}</button>{message&&<p className="mt-3 rounded-2xl bg-[#f7f8fa] p-3 text-xs text-[#667085]">{message}</p>}</div>
}