"use client";
import {useEffect,useState} from "react";
import {createClient} from "@/lib/supabase/client";
import {PublicTrackingMap} from "@/components/public-tracking-map";
import type {PublicTripTracking} from "@/types/jelad";
export default function PublicTrackingPage({params}:{params:Promise<{token:string}>}){
 const [trip,setTrip]=useState<PublicTripTracking|null>(null);const [error,setError]=useState("");
 const [driver,setDriver]=useState<[number,number]|null>(null);
 useEffect(()=>{let channel:any;
  (async()=>{const {token}=await params;const r=await fetch("/api/trip/share/"+token);const d=await r.json();if(!r.ok){setError(d.error||"الرابط غير متاح");return;}setTrip(d.trip);if(d.trip?.driver?.longitude!=null&&d.trip?.driver?.latitude!=null)setDriver([d.trip.driver.longitude,d.trip.driver.latitude]);
   const supabase=createClient();channel=supabase.channel("public-trip-"+token).on("postgres_changes",{event:"UPDATE",schema:"public",table:"trip_live_locations",filter:"share_token=eq."+token},payload=>{const x:any=payload.new;if(x?.longitude!=null&&x?.latitude!=null)setDriver([x.longitude,x.latitude])}).subscribe();
  })();return()=>{if(channel)createClient().removeChannel(channel)}},[]);
 if(error)return <main dir="rtl" className="grid min-h-screen place-items-center bg-[#f7f8fa] p-6"><div className="rounded-3xl bg-white p-7 text-center shadow-sm ring-1 ring-[#eaecf0]"><h1 className="text-xl font-semibold">الرابط غير متاح</h1><p className="mt-2 text-sm text-[#667085]">{error}</p></div></main>;
 if(!trip)return <main dir="rtl" className="grid min-h-screen place-items-center bg-[#f7f8fa] text-sm">جارٍ تحميل الرحلة…</main>;
 const center=driver||[(trip.pickup as any)?.longitude||35.91,(trip.pickup as any)?.latitude||31.95] as [number,number];
 return <main dir="rtl" className="min-h-screen bg-[#f7f8fa] p-4"><div className="mx-auto max-w-3xl"><div className="mb-4"><p className="text-xs font-semibold tracking-[.16em] text-[#c89252]">JELAD · مسوار مطمئن</p><h1 className="mt-1 text-2xl font-bold">تتبع الرحلة مباشرة</h1></div><PublicTrackingMap driver={driver} center={center}/><section className="mt-4 rounded-3xl bg-white p-5 ring-1 ring-[#eaecf0]"><div className="flex items-center gap-4"><div className="grid h-14 w-14 place-items-center overflow-hidden rounded-full bg-[#eef2f6]">{trip.driver?.avatar_url?<img src={trip.driver.avatar_url} alt="" className="h-full w-full object-cover"/>:"🚗"}</div><div><h2 className="font-semibold">{trip.driver?.name||"السائق"}</h2><p className="text-sm text-[#667085]">★ {Number(trip.driver?.rating||0).toFixed(1)} · {trip.vehicle?.make} {trip.vehicle?.model}</p><p className="text-sm text-[#667085]">لوحة المركبة: {trip.vehicle?.plate_number||"—"}</p></div></div><p className="mt-5 rounded-2xl bg-[#f7f8fa] p-4 text-sm">الحالة: <b>{trip.status}</b></p></section></div></main>;
}