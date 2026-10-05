"use client";

import { useEffect, useState } from "react";

type Contact={id:string;contact_name:string;contact_phone:string;relationship:string|null;is_verified:boolean};

export default function SafetyPage(){
  const [contacts,setContacts]=useState<Contact[]>([]);
  const [name,setName]=useState(""); const [phone,setPhone]=useState(""); const [relationship,setRelationship]=useState("");
  const [jobId,setJobId]=useState(""); const [shareUrl,setShareUrl]=useState(""); const [message,setMessage]=useState("");

  async function loadContacts(){
    const r=await fetch("/api/safety/trusted-contacts",{cache:"no-store"});
    const d=await r.json(); if(r.ok)setContacts(d.contacts||[]);
  }
  useEffect(()=>{loadContacts()},[]);

  async function addContact(e:React.FormEvent){
    e.preventDefault(); setMessage("");
    const r=await fetch("/api/safety/trusted-contacts",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({contactName:name,contactPhone:phone,relationship})});
    const d=await r.json(); if(!r.ok){setMessage(d.error||"تعذر الإضافة");return}
    setName("");setPhone("");setRelationship("");await loadContacts();setMessage("تمت إضافة جهة الاتصال.");
  }

  async function createShare(){
    setMessage("");
    const r=await fetch("/api/safety/share",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({jobId})});
    const d=await r.json(); if(!r.ok){setMessage(d.error||"تعذر إنشاء رابط المشاركة");return}
    setShareUrl(window.location.origin+d.shareUrl);
  }

  async function sos(){
    if(!confirm("تأكيد إرسال SOS للرحلة الحالية؟"))return;
    const r=await fetch("/api/safety",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({jobId:jobId||null,category:"SOS",severity:"CRITICAL",description:"SOS triggered from JELAD Safety Center"})});
    const d=await r.json(); setMessage(r.ok?"تم تسجيل SOS وإطلاق مسار الطوارئ.":(d.error||"تعذر إرسال SOS"));
  }

  return <main dir="rtl" className="min-h-screen bg-[#f7f8fa] p-5 text-[#101828]"><div className="mx-auto max-w-4xl">
    <header><p dir="ltr" className="text-xs font-semibold tracking-[.16em] text-[#c89252]">JELAD SAFETY</p><h1 className="mt-2 text-3xl font-semibold">مركز الأمان الشخصي</h1><p className="mt-2 text-sm text-[#667085]">SOS، مشاركة الرحلة، وجهات الاتصال الموثوقة.</p></header>

    <section className="mt-6 rounded-3xl bg-white p-6 ring-1 ring-[#eaecf0]"><h2 className="font-semibold">الرحلة الحالية</h2><input value={jobId} onChange={e=>setJobId(e.target.value)} placeholder="معرّف الرحلة" className="mt-4 w-full rounded-2xl border border-[#d0d5dd] px-4 py-3 text-sm" />
      <div className="mt-4 grid gap-3 sm:grid-cols-2"><button onClick={sos} className="rounded-2xl bg-[#b42318] px-5 py-4 font-semibold text-white">🆘 SOS للطوارئ</button><button onClick={createShare} className="rounded-2xl bg-[#182230] px-5 py-4 font-semibold text-white">🔗 إنشاء رابط مشاركة</button></div>
      {shareUrl&&<div className="mt-4 rounded-2xl bg-[#f7f8fa] p-4 text-sm break-all">{shareUrl}</div>}
    </section>

    <section className="mt-5 rounded-3xl bg-white p-6 ring-1 ring-[#eaecf0]"><h2 className="font-semibold">جهات الاتصال الموثوقة</h2><form onSubmit={addContact} className="mt-4 grid gap-3 sm:grid-cols-3"><input value={name} onChange={e=>setName(e.target.value)} placeholder="الاسم" required className="rounded-2xl border border-[#d0d5dd] px-4 py-3 text-sm"/><input value={phone} onChange={e=>setPhone(e.target.value)} placeholder="07xxxxxxxx" required className="rounded-2xl border border-[#d0d5dd] px-4 py-3 text-sm" dir="ltr"/><input value={relationship} onChange={e=>setRelationship(e.target.value)} placeholder="صلة القرابة" className="rounded-2xl border border-[#d0d5dd] px-4 py-3 text-sm"/><button className="rounded-2xl bg-[#c89252] px-5 py-3 font-semibold text-white sm:col-span-3">إضافة جهة اتصال</button></form>
      <div className="mt-5 divide-y divide-[#eaecf0]">{contacts.map(c=><div key={c.id} className="flex items-center justify-between py-4"><div><p className="font-medium">{c.contact_name}</p><p dir="ltr" className="text-sm text-[#667085]">{c.contact_phone}</p></div><span className="text-xs text-[#667085]">{c.relationship||"جهة موثوقة"}</span></div>)}</div>
    </section>
    {message&&<p className="mt-4 rounded-2xl bg-white p-4 text-sm ring-1 ring-[#eaecf0]">{message}</p>}
  </div></main>
}
