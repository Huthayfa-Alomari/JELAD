"use client";

import { useEffect, useState } from "react";

type Tracking = any;

const labels: Record<string,string> = {
  REQUESTED:"Request received", SEARCHING:"Finding your driver", ASSIGNED:"Driver assigned",
  DRIVER_ARRIVING:"Driver is on the way", IN_PROGRESS:"Trip in progress",
  COMPLETED:"Trip completed", CANCELLED:"Trip cancelled", REJECTED:"Trip rejected", EXPIRED:"Trip expired"
};

export function TripTracker({ jobId }: { jobId: string }) {
  const [data,setData]=useState<Tracking|null>(null);
  const [error,setError]=useState("");

  useEffect(() => {
    let mounted=true;
    const load=async()=>{
      const r=await fetch(`/api/jobs/${jobId}/tracking`,{cache:"no-store"});
      const d=await r.json();
      if(!r.ok){if(mounted)setError(d.error||"Tracking unavailable");return;}
      if(mounted){setData(d);setError("");}
    };
    load();
    const t=setInterval(load,5000);
    return()=>{mounted=false;clearInterval(t)};
  },[jobId]);

  if(error) return <div className="mt-4 rounded-2xl bg-[#fff7ed] p-4 text-sm text-[#9a3412]">{error}</div>;
  if(!data) return <div className="mt-4 rounded-2xl bg-white p-4 text-sm text-[#667085]">Connecting to live trip…</div>;

  const d=data.driver;
  const v=d?.vehicle;
  return <div className="mt-4 rounded-3xl bg-white p-5 ring-1 ring-[#eaecf0]">
    <div className="flex items-start justify-between gap-4">
      <div><p className="text-xs uppercase tracking-[.14em] text-[#c89252]">LIVE TRIP</p>
      <p className="mt-1 text-lg font-semibold">{labels[data.job.status]||data.job.status}</p></div>
      {data.job.status!=="COMPLETED"&&data.job.status!=="CANCELLED"&&<span className="h-2.5 w-2.5 rounded-full bg-[#16a34a] mt-2"/>}
    </div>
    {d&&<div className="mt-4 rounded-2xl bg-[#f7f8fa] p-4"><p className="font-semibold">{d.name}</p><p className="mt-1 text-sm text-[#667085]">★ {Number(d.rating||5).toFixed(1)}{v? ` · ${v.make} ${v.model} · ${v.plate}`:""}</p>
      {d.latitude!=null&&<p className="mt-2 text-xs text-[#98a2b3]">Driver location updated live</p>}
    </div>}
    <div className="mt-4 h-2 overflow-hidden rounded-full bg-[#eaecf0]"><div className="h-full rounded-full bg-[#182230] transition-all" style={{width:data.job.status==="REQUESTED"||data.job.status==="SEARCHING"?"18%":data.job.status==="ASSIGNED"?"42%":data.job.status==="DRIVER_ARRIVING"?"65%":data.job.status==="IN_PROGRESS"?"82%":"100%"}}/></div>
  </div>;
}
