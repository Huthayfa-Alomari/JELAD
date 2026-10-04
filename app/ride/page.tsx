"use client";
import { useState } from "react";
import { RequestButton } from "./request-button";
import { RideMap } from "@/components/ride-map";
import { TripTracker } from "./trip-tracker";

const rides=[["Economy","Everyday rides","2.25 JOD","3 min"],["Comfort","More space","3.10 JOD","5 min"],["XL","Up to 6 people","4.40 JOD","6 min"]];

export default function RidePage(){
 const [selected,setSelected]=useState(0);
 const [destination,setDestination]=useState("");
 const [points,setPoints]=useState<{id:string;pickup:[number,number];destination:[number,number]}|null>(null);
 return <main className="min-h-screen bg-[#f7f8fa] text-[#101828]">
  <header className="border-b border-[#eaecf0] bg-white"><div className="mx-auto flex h-16 max-w-6xl items-center gap-4 px-5"><a href="/" className="text-sm text-[#667085]">← Back</a><div className="h-5 w-px bg-[#eaecf0]"/><span className="font-semibold tracking-[.16em]">JELAD</span></div></header>
  <div className="mx-auto grid max-w-6xl gap-6 px-5 py-6 lg:grid-cols-[1fr_390px]">
   <section className="min-h-[560px] rounded-[28px] bg-[#dfe5eb] p-4 sm:p-6"><RideMap pickup={points?.pickup} destination={points?.destination}/></section>
   <section className="rounded-[28px] bg-white p-5 shadow-sm ring-1 ring-[#eaecf0] sm:p-6">
    <p className="text-xs font-medium text-[#667085]">JELAD RIDE</p><h1 className="mt-1 text-2xl font-semibold tracking-[-.03em]">Where to?</h1>
    <div className="mt-5 space-y-3"><div className="rounded-2xl border border-[#eaecf0] p-4"><p className="text-xs text-[#98a2b3]">Pickup</p><p className="mt-1 text-sm font-medium">{points?"Location selected":"Current location"}</p></div><div className="rounded-2xl border border-[#eaecf0] p-4"><p className="text-xs text-[#98a2b3]">Destination</p><input value={destination} onChange={e=>setDestination(e.target.value)} className="mt-1 w-full bg-transparent text-sm font-medium outline-none" placeholder="Amman, Zarqa, airport…" /></div></div>
    <div className="mt-6"><div className="mb-3 flex items-center justify-between"><h2 className="font-semibold">Choose a ride</h2><span className="text-xs text-[#667085]">Estimated</span></div><div className="space-y-2">{rides.map(([name,desc,price,time],i)=><button key={name} onClick={()=>setSelected(i)} className={`flex w-full items-center gap-3 rounded-2xl border p-4 text-left transition ${selected===i?"border-[#182230] bg-[#f7f8fa]":"border-[#eaecf0]"}`}><div className="grid h-10 w-10 place-items-center rounded-xl bg-[#eef2f6]">▰</div><div className="min-w-0 flex-1"><p className="text-sm font-semibold">{name}</p><p className="text-xs text-[#667085]">{desc} · {time}</p></div><span className="text-sm font-semibold">{price}</span></button>)}</div></div>
    <RequestButton destinationAddress={destination} rideClass={rides[selected][0]} onCreated={setPoints}/>{points?.id&&<TripTracker jobId={points.id}/>}
   </section>
  </div>
 </main>
}