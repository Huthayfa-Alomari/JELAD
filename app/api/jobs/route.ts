import { NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";

const rates={Economy:2.25,Comfort:3.1,XL:4.4} as const;
function distanceKm(a:[number,number],b:[number,number]){const R=6371;const dLat=(b[0]-a[0])*Math.PI/180;const dLng=(b[1]-a[1])*Math.PI/180;const x=Math.sin(dLat/2)**2+Math.cos(a[0]*Math.PI/180)*Math.cos(b[0]*Math.PI/180)*Math.sin(dLng/2)**2;return 2*R*Math.asin(Math.sqrt(x));}
export async function POST(req:NextRequest){
 const supabase=await createClient(); const {data:{user}}=await supabase.auth.getUser();
 if(!user)return Response.json({error:"Authentication required"},{status:401});
 const body=await req.json(); const destinationAddress=String(body.destinationAddress||"").trim(); const type=body.type==="DELIVERY"||body.type==="CARGO"?"RIDE":(body.type||"RIDE");
 if(!destinationAddress)return Response.json({error:"Destination is required"},{status:400});
 const lat=Number(body.pickupLat),lng=Number(body.pickupLng); if(!Number.isFinite(lat)||!Number.isFinite(lng))return Response.json({error:"Pickup location is required"},{status:400});
 const geo=await fetch("https://nominatim.openstreetmap.org/search?format=jsonv2&limit=1&countrycodes=jo&q="+encodeURIComponent(destinationAddress+", Jordan"),{headers:{"User-Agent":"JELAD/1.0 mobility platform"}});
 if(!geo.ok)return Response.json({error:"Geocoding service unavailable"},{status:502});
 const places=await geo.json(); if(!places[0])return Response.json({error:"Destination could not be found in Jordan"},{status:422});
 const dlat=Number(places[0].lat),dlng=Number(places[0].lon),km=distanceKm([lat,lng],[dlat,dlng]);
 const base=rates[(body.rideClass||"Economy") as keyof typeof rates]||rates.Economy;
 const estimate=Math.max(base,Math.round((base+km*0.45)*100)/100);
 const {data,error}=await supabase.rpc("create_job",{p_type:type,p_pickup_address:"Current location",p_pickup_lat:lat,p_pickup_lng:lng,p_destination_address:places[0].display_name,p_destination_lat:dlat,p_destination_lng:dlng,p_estimated_amount:estimate,p_notes:null});
 if(error)return Response.json({error:error.message},{status:400});
 return Response.json({job:data,estimate,distanceKm:Math.round(km*10)/10});
}
export async function GET(){
 const supabase=await createClient(); const {data:{user}}=await supabase.auth.getUser(); if(!user)return Response.json({error:"Authentication required"},{status:401});
 const {data,error}=await supabase.from("jobs").select("*,pickup:pickup_location_id(*),destination:destination_location_id(*)").eq("customer_id",user.id).order("created_at",{ascending:false}).limit(30);
 if(error)return Response.json({error:error.message},{status:400}); return Response.json({jobs:data});
}