"use client";
import {useEffect,useState} from "react";
import {OpsMap} from "@/components/ops-map";

const activeStatuses=["COMPLETED","CANCELLED","REJECTED","EXPIRED"];
function Pill({children,critical=false}:{children:React.ReactNode;critical?:boolean}){return <span className={`rounded-full px-2.5 py-1 text-[11px] font-semibold ${critical?"bg-red-50 text-red-700":"bg-[#eef2f6] text-[#475467]"}`}>{children}</span>}
export default function Ops(){
 const [data,setData]=useState<any>({jobs:[],drivers:[],incidents:[],safetyEvents:[],devices:[],tamper:[],crashes:[],deviations:[]});
 const [error,setError]=useState("");
 const [staleDevices,setStaleDevices]=useState(0);
 useEffect(()=>{let mounted=true;async function load(){try{const r=await fetch("/api/ops",{cache:"no-store"});const d=await r.json();if(!r.ok){setError(d.error||"Operations access required");return}if(mounted){setData(d); const h=await fetch("/api/ops/safety-health",{cache:"no-store"}); const hd=await h.json(); if(h.ok)setStaleDevices(Number(hd.staleDevicesDetected||0));}}catch(e){setError("تعذر الاتصال بمركز العمليات")}}load();const t=setInterval(load,10000);return()=>{mounted=false;clearInterval(t)}},[]);
 const jobs=data.jobs||[],drivers=data.drivers||[],incidents=data.incidents||[],events=data.safetyEvents||[],devices=data.devices||[],tamper=data.tamper||[],crashes=data.crashes||[],deviations=data.deviations||[];
 const active=jobs.filter((j:any)=>!activeStatuses.includes(j.status));
 const openSafety=[...events,...incidents].filter((x:any)=>!["RESOLVED","FALSE_POSITIVE","resolved","closed"].includes(x.status));
 const critical=events.filter((x:any)=>x.severity==="CRITICAL"||x.severity==="HIGH").length+crashes.length+tamper.length;
 return <main dir="rtl" className="min-h-screen bg-[#f7f8fa] p-5 text-[#101828]"><div className="mx-auto max-w-7xl">
  <header className="flex flex-wrap items-end justify-between gap-4"><div><p dir="ltr" className="text-xs font-semibold uppercase tracking-[.16em] text-[#c89252]">JELAD OPS / SAFETY</p><h1 className="mt-1 text-3xl font-semibold">مركز العمليات والسلامة</h1><p className="mt-1 text-sm text-[#667085]">مراقبة الرحلات والأجهزة والتنبيهات الحساسة من لوحة واحدة.</p></div><Pill>تحديث تلقائي · 10 ثوانٍ</Pill></header>
  {error?<p className="mt-5 rounded-2xl bg-white p-5 text-sm text-[#667085]">{error}</p>:<>
   <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-6">
    {[["رحلات نشطة",active.length],["سائقون متصلون",drivers.filter((d:any)=>d.status?.toLowerCase()==="online").length],["تنبيهات مفتوحة",openSafety.length],["حرجة",critical],["أجهزة Safety Box",devices.filter((d:any)=>d.status==="ACTIVE").length],["GPS متأخر",staleDevices]].map(([a,b])=><div key={String(a)} className="rounded-3xl bg-white p-5 ring-1 ring-[#eaecf0]"><p className="text-sm text-[#667085]">{a}</p><p className="mt-3 text-3xl font-semibold">{b}</p></div>)}
   </div>
   <div className="mt-5 overflow-hidden rounded-3xl bg-white p-3 ring-1 ring-[#eaecf0]"><OpsMap drivers={drivers}/></div>
   <section className="mt-5 grid gap-5 lg:grid-cols-2">
    <div className="rounded-3xl bg-white ring-1 ring-[#eaecf0]"><div className="border-b border-[#eaecf0] p-5"><h2 className="font-semibold">تنبيهات السلامة</h2></div><div className="divide-y divide-[#eaecf0]">{[...events,...crashes.map((x:any)=>({...x,event_type:"CRASH"})),...tamper.map((x:any)=>({...x,event_type:"DEVICE_TAMPER"})),...deviations.map((x:any)=>({...x,event_type:"ROUTE_DEVIATION"}))].slice(0,12).map((e:any,i:number)=><div key={e.id||i} className="flex items-center justify-between gap-3 p-4"><div><p className="text-sm font-medium">{e.event_type||e.category}</p><p className="mt-1 text-xs text-[#667085]">{new Date(e.occurred_at||e.detected_at||e.created_at).toLocaleString("ar-JO")}</p></div><Pill critical={e.severity==="CRITICAL"||e.severity==="HIGH"}>{e.severity||e.status||"OPEN"}</Pill></div>)}</div></div>
    <div className="rounded-3xl bg-white ring-1 ring-[#eaecf0]"><div className="border-b border-[#eaecf0] p-5"><h2 className="font-semibold">حالة الأجهزة</h2></div><div className="divide-y divide-[#eaecf0]">{devices.slice(0,10).map((d:any)=><div key={d.id} className="flex items-center justify-between gap-3 p-4"><div><p dir="ltr" className="text-sm font-medium">{d.device_type} · {d.serial_number||"بدون Serial"}</p><p className="mt-1 text-xs text-[#667085]">آخر اتصال: {d.last_seen_at?new Date(d.last_seen_at).toLocaleString("ar-JO"):"لا يوجد"}</p></div><Pill critical={d.status!=="ACTIVE"}>{d.status}</Pill></div>)}</div></div>
   </section>
   <div className="mt-5 overflow-hidden rounded-3xl bg-white ring-1 ring-[#eaecf0]"><div className="border-b border-[#eaecf0] p-5"><h2 className="font-semibold">الرحلات النشطة</h2></div><div className="divide-y divide-[#eaecf0]">{active.slice(0,20).map((j:any)=><div key={j.id} className="grid gap-2 p-5 sm:grid-cols-[100px_120px_1fr_150px_100px] sm:items-center"><span dir="ltr" className="text-xs font-semibold">{j.id.slice(0,8)}</span><span className="text-sm">{j.type}</span><span className="text-sm text-[#667085]">{j.destination?.address||"الوجهة غير محددة"}</span><Pill>{j.status}</Pill><span className="text-sm font-semibold sm:text-left">{Number(j.estimated_amount||j.quoted_amount||0).toFixed(2)} JOD</span></div>)}</div></div>
  </>}</div></main>
}