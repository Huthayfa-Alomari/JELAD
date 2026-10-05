"use client";

import { useEffect, useState } from "react";

export default function IdentityPage() {
  const [data,setData]=useState<any>({});
  const [subjectType,setSubjectType]=useState<"CUSTOMER"|"DRIVER">("CUSTOMER");
  const [gender,setGender]=useState("");
  const [documentType,setDocumentType]=useState("NATIONAL_ID");
  const [documentPath,setDocumentPath]=useState("");
  const [selfiePath,setSelfiePath]=useState("");
  const [message,setMessage]=useState("");

  async function load(){const r=await fetch("/api/identity");const d=await r.json();if(r.ok){setData(d);setGender(d.profile?.gender||d.driver?.gender||"");}}
  useEffect(()=>{load()},[]);

  async function submit(){
    setMessage("");
    const r=await fetch("/api/identity",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({subjectType,gender,documentType,documentStoragePath:documentPath,selfieStoragePath:selfiePath})});
    const d=await r.json();setMessage(r.ok?"تم إرسال طلب التحقق للمراجعة.":"تعذر إرسال الطلب: "+(d.error||"Unknown error"));if(r.ok)load();
  }

  const latest=(data.verifications||[]).find((x:any)=>x.subject_type===subjectType);
  return <main dir="rtl" className="min-h-screen bg-[#f7f8fa] p-5 text-[#101828]">
    <div className="mx-auto max-w-2xl">
      <a href="/profile" className="text-sm text-[#667085]">← الحساب</a>
      <div className="mt-5 rounded-[30px] bg-white p-6 ring-1 ring-[#eaecf0] sm:p-8">
        <p className="text-xs font-semibold uppercase tracking-[.16em] text-[#c89252]">JELAD TRUST</p>
        <h1 className="mt-2 text-3xl font-semibold">توثيق الهوية</h1>
        <p className="mt-3 text-sm leading-7 text-[#667085]">التوثيق يحمي العملاء والسائقين ويتيح مزايا الرحلات النسائية. وثائقك لا تظهر للسائقين.</p>
        <div className="mt-6 grid grid-cols-2 gap-2 rounded-2xl bg-[#f7f8fa] p-1">
          {([["CUSTOMER","عميلة"],["DRIVER","سائقة"] ] as const).map(([v,l])=><button key={v} onClick={()=>setSubjectType(v)} className={`rounded-xl px-4 py-3 text-sm font-semibold ${subjectType===v?"bg-white shadow-sm":"text-[#667085]"}`}>{l}</button>)}
        </div>
        <div className="mt-5 space-y-3">
          <label className="block text-sm font-medium">الجنس<select value={gender} onChange={e=>setGender(e.target.value)} className="mt-2 w-full rounded-2xl border border-[#eaecf0] p-3"><option value="">اختر</option><option value="female">أنثى</option><option value="male">ذكر</option></select></label>
          <label className="block text-sm font-medium">نوع الوثيقة<select value={documentType} onChange={e=>setDocumentType(e.target.value)} className="mt-2 w-full rounded-2xl border border-[#eaecf0] p-3"><option value="NATIONAL_ID">هوية شخصية</option><option value="PASSPORT">جواز سفر</option></select></label>
          <input value={documentPath} onChange={e=>setDocumentPath(e.target.value)} placeholder="مسار ملف الهوية بعد الرفع الآمن" className="w-full rounded-2xl border border-[#eaecf0] p-3 text-sm"/>
          <input value={selfiePath} onChange={e=>setSelfiePath(e.target.value)} placeholder="مسار ملف السيلفي بعد الرفع الآمن" className="w-full rounded-2xl border border-[#eaecf0] p-3 text-sm"/>
        </div>
        <button onClick={submit} disabled={!gender} className="mt-5 w-full rounded-2xl bg-[#182230] py-4 text-sm font-semibold text-white disabled:opacity-40">إرسال للتحقق</button>
        {message&&<p className="mt-4 rounded-2xl bg-[#eef2f6] p-4 text-sm">{message}</p>}
        {latest&&<div className="mt-5 rounded-2xl border border-[#eaecf0] p-4 text-sm"><p className="font-semibold">الحالة: {latest.status}</p>{latest.rejection_reason&&<p className="mt-1 text-[#b42318]">{latest.rejection_reason}</p>}</div>}
      </div>
    </div>
  </main>
}
