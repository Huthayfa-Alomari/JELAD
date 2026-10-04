"use client";

import { useEffect, useRef } from "react";
import maplibregl from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";

type Props = {
  pickup?: [number, number] | null;
  destination?: [number, number] | null;
};

const style: maplibregl.StyleSpecification = {
  version: 8,
  sources: {
    osm: {
      type: "raster",
      tiles: ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
      tileSize: 256,
      attribution: "© OpenStreetMap contributors",
    },
  },
  layers: [{ id: "osm", type: "raster", source: "osm" }],
};

export function RideMap({ pickup, destination }: Props) {
  const ref = useRef<HTMLDivElement>(null);
  const map = useRef<maplibregl.Map | null>(null);

  useEffect(() => {
    if (!ref.current || map.current) return;
    map.current = new maplibregl.Map({
      container: ref.current,
      style,
      center: [35.91, 31.95],
      zoom: 9,
      attributionControl: true,
    });
    map.current.addControl(new maplibregl.NavigationControl({ showCompass: false }), "top-right");
    return () => { map.current?.remove(); map.current = null; };
  }, []);

  useEffect(() => {
    const m = map.current;
    if (!m) return;
    const draw = () => {
      const points = [pickup, destination].filter(Boolean) as [number, number][];
      if (!points.length) return;
      if (m.getLayer("ride-route")) m.removeLayer("ride-route");
      if (m.getSource("ride-route")) m.removeSource("ride-route");
      const features = points.map((p) => ({ type: "Feature" as const, geometry: { type: "Point" as const, coordinates: p }, properties: {} }));
      if (points.length === 2) {
        m.addSource("ride-route", {
          type: "geojson",
          data: { type: "Feature", geometry: { type: "LineString", coordinates: points }, properties: {} },
        });
        m.addLayer({ id: "ride-route", type: "line", source: "ride-route", paint: { "line-width": 4, "line-opacity": 0.75 } });
      }
      for (const f of features) new maplibregl.Marker().setLngLat(f.geometry.coordinates as [number, number]).addTo(m);
      if (points.length === 1) m.flyTo({ center: points[0], zoom: 14 });
      else {
        const bounds = new maplibregl.LngLatBounds(points[0], points[0]);
        points.slice(1).forEach((p) => bounds.extend(p));
        m.fitBounds(bounds, { padding: 80, maxZoom: 14 });
      }
    };
    if (m.isStyleLoaded()) draw(); else m.once("load", draw);
  }, [pickup, destination]);

  return <div ref={ref} className="h-full min-h-[520px] w-full overflow-hidden rounded-[22px]" />;
}
