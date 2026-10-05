"use client";
import {useEffect,useRef} from "react";
import maplibregl from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";
export function PublicTrackingMap({driver,center}:{driver:[number,number]|null;center:[number,number]}) {
 const ref=useRef<HTMLDivElement|null>(null); const map=useRef<maplibregl.Map|null>(null); const marker=useRef<maplibregl.Marker|null>(null);
 useEffect(()=>{if(!ref.current)return;const m=new maplibregl.Map({container:ref.current,style:{version:8,sources:{osm:{type:"raster",tiles:["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],tileSize:256,attribution:"© OpenStreetMap contributors"}},layers:[{id:"osm",type:"raster",source:"osm"}]},center,zoom:13,attributionControl:{}});map.current=m;return()=>m.remove()},[]);
 useEffect(()=>{if(!map.current)return;if(!marker.current){marker.current=new maplibregl.Marker({color:"#182230"}).setLngLat(driver||center).addTo(map.current)}else marker.current.setLngLat(driver||center)},[driver,center]);
 return <div ref={ref} className="h-[360px] w-full overflow-hidden rounded-3xl"/>;
}
