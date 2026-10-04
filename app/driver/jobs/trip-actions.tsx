"use client";

import { useState } from "react";

type Action = "ARRIVED" | "START" | "COMPLETE";

const labels: Record<Action, string> = {
  ARRIVED: "I arrived",
  START: "Start trip",
  COMPLETE: "Complete trip",
};

export function TripActions({
  jobId,
  status,
  onChanged,
}: {
  jobId: string;
  status: string;
  onChanged?: (status: string) => void;
}) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  const action =
    status === "ASSIGNED"
      ? "ARRIVED"
      : status === "DRIVER_ARRIVING"
        ? "START"
        : status === "IN_PROGRESS"
          ? "COMPLETE"
          : null;

  if (!action) return null;

  async function transition() {
    setBusy(true);
    setError("");
    const response = await fetch(`/api/driver/jobs/${jobId}/transition`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ action }),
    });
    const data = await response.json();
    setBusy(false);

    if (!response.ok) {
      setError(data.error || "Unable to update trip");
      return;
    }

    onChanged?.(data.job?.status || "");
  }

  return (
    <div className="mt-4">
      <button
        onClick={transition}
        disabled={busy}
        className="w-full rounded-2xl bg-[#182230] py-3.5 text-sm font-semibold text-white disabled:opacity-50"
      >
        {busy ? "Updating…" : labels[action]}
      </button>
      {error && <p className="mt-2 text-xs text-red-600">{error}</p>}
    </div>
  );
}
