"use client";
import {useEffect,useState} from "react";
import type {Landmark} from "@/types/jelad";
export function LandmarkSelector({value,onChange}:{value:Landmark|null;onChange:(landmark:Landmark|null)=>void}) {
 const [q,setQ]=useState(""); const [items,setItems]=useState<Landmark[]>([]);
 useEffect(()=>{if(q.trim().length<2){setItems([]);return;}const t=setTimeout(async()=>{const r=await fetch("/api/landmarks/search?q="+encodeURIComponent(q));const d=await r.json();if(r.ok)setItems(d.landmarks||[])},250);return()=>clearTimeout(t)},[q]);
 return <div className="relative" dir="rtl"><input value={value?value.name_ar:q} onChange={e=>{onChange(null);setQ(e.target.value)}} className="w-full rounded-2xl border border-[#eaecf0] bg-white px-4 py-3" placeholder="ابحث عن معلم أو بوابة…"/>{items.length>0&&<div className="absolute z-20 mt-2 w-full overflow-hidden rounded-2xl border border-[#eaecf0] bg-white shadow-xl">{items.map(x=><button key={x.id} onClick={()=>{onChange(x);setQ(x.name_ar)}} className="block w-full border-b border-[#f2f4f7] p-4 text-right hover:bg-[#f7f8fa]"><b>{x.name_ar}</b><span className="block text-xs text-[#667085]">{x.name_en} · {x.city}</span></button>)}</div>}</div>;
}
