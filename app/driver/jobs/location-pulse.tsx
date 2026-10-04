'use client';

import { useEffect } from 'react';

export function DriverLocationPulse({ enabled = true }: { enabled?: boolean }) {
  useEffect(() => {
    if (!enabled || !navigator.geolocation) return;
    let timer: ReturnType<typeof setInterval> | undefined;
    const send = () => navigator.geolocation.getCurrentPosition(async (p) => {
      await fetch('/api/driver/location', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ lat: p.coords.latitude, lng: p.coords.longitude }),
      }).catch(() => undefined);
    }, () => undefined, { enableHighAccuracy: true, maximumAge: 5000, timeout: 10000 });
    send();
    timer = setInterval(send, 10000);
    return () => { if (timer) clearInterval(timer); };
  }, [enabled]);

  return null;
}
