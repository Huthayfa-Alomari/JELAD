"use client";

import { useEffect, useRef } from "react";
import maplibregl from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";

export function OpsMap({ drivers }: { drivers: any[] }) {
  const ref=useRef<HTMLDivElement>(null); const map=useRef<maplibregl.Map|null>(null); const markers=useRef<Map<string,maplibregl.Marker>>(new Map());
  useEffect(()=>{if(!ref.current||map.current)return;
    map.current=new maplibregl.Map({container:ref.current,style:{version:8,sources:{osm:{type:"raster",tiles:["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],tileSize:256,attribution:"© OpenStreetMap contributors"}},layers:[{id:"osm",type:"raster",source:"osm"}]},center:[35.91,31.95],zoom:10,attributionControl:{}});
    return()=>{map.current?.remove();map.current=null};
  },[]);
  useEffect(()=>{const m=map.current;if(!m)return;
    const live=new Set<string>();
    drivers.filter(d=>d.latitude!=null&&d.longitude!=null).forEach(d=>{live.add(d.id);let marker=markers.current.get(d.id);
      if(!marker){const el=document.createElement("div");el.className="h-7 w-7 rounded-full border-2 border-white bg-[#182230] shadow-md";marker=new maplibregl.Marker({element:el}).setLngLat([Number(d.longitude),Number(d.latitude)]).setPopup(new maplibregl.Popup({offset:12}).setText(d.status+" · ★ "+Number(d.rating||5).toFixed(1))).addTo(m);markers.current.set(d.id,marker)}else marker.setLngLat([Number(d.longitude),Number(d.latitude)]);
    });
    markers.current.forEach((marker,id)=>{if(!live.has(id)){marker.remove();markers.current.delete(id)}});
  },[drivers]);
  return <div ref={ref} className="h-[420px] w-full overflow-hidden rounded-3xl"/>;
}
