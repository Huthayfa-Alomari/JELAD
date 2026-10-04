import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata={title:"JELAD — Mobility & Logistics",description:"A modern mobility and logistics platform built for Jordan."};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="en" dir="ltr"><body>{children}</body></html>}
