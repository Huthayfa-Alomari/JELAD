"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";

const items=[["⌂","Home","/"],["⌖","Ride","/ride"],["▣","Delivery","/delivery"],["◷","Activity","/activity"],["◉","Wallet","/wallet"],["⚙","Settings","/settings"]];

export function AppShell({children}:{children:React.ReactNode}){
 const path=usePathname();
 return <div className="min-h-screen bg-[#f7f8fa] text-[#101828]">
  <aside className="fixed inset-y-0 left-0 z-30 hidden w-64 border-r border-[#eaecf0] bg-white lg:block">
   <div className="flex h-full flex-col p-5"><Link href="/" className="flex items-center gap-3 px-2 py-3"><span className="grid h-9 w-9 place-items-center rounded-xl bg-[#182230] font-bold text-white">J</span><span className="font-semibold tracking-[.18em]">JELAD</span></Link>
   <nav className="mt-8 space-y-1">{items.map(([icon,label,href])=><Link key={href} href={href} className={`flex items-center gap-3 rounded-2xl px-3 py-3 text-sm font-medium ${path===href?"bg-[#eef2f6]":"text-[#667085] hover:bg-[#f7f8fa]"}`}><span>{icon}</span>{label}</Link>)}</nav>
   <div className="mt-auto rounded-2xl bg-[#182230] p-4 text-white"><p className="text-xs text-white/50">JELAD</p><p className="mt-1 text-sm font-semibold">Move with confidence.</p><Link href="/profile" className="mt-4 block text-xs text-white/60">Profile →</Link></div></div>
  </aside>
  <div className="lg:pl-64"><header className="sticky top-0 z-20 border-b border-[#eaecf0] bg-white/90 backdrop-blur"><div className="flex h-16 items-center justify-between px-5"><Link href="/" className="flex items-center gap-2 lg:hidden"><span className="grid h-8 w-8 place-items-center rounded-lg bg-[#182230] text-sm font-bold text-white">J</span><span className="font-semibold tracking-[.16em]">JELAD</span></Link><div className="hidden text-sm text-[#667085] lg:block">Mobility & Logistics</div><Link href="/profile" className="rounded-full border border-[#eaecf0] px-3 py-2 text-xs font-semibold">Account</Link></div></header><main>{children}</main></div>
  <nav className="fixed inset-x-3 bottom-3 z-40 flex justify-around rounded-2xl border border-[#eaecf0] bg-white/95 p-2 shadow-xl backdrop-blur lg:hidden">{items.map(([icon,label,href])=><Link key={href} href={href} className={`flex min-w-14 flex-col items-center gap-1 rounded-xl px-2 py-2 text-[10px] font-medium ${path===href?"bg-[#182230] text-white":"text-[#667085]"}`}><span className="text-base">{icon}</span>{label}</Link>)}</nav>
 </div>
}