# JELAD Architecture

## Product surfaces
- Customer: Home, Ride, Delivery, Activity, Wallet, Profile
- Driver: online/offline, jobs, earnings, vehicle
- Operations: live jobs, drivers, alerts, safety, audit
- Business: employees, budgets, invoices, scheduled mobility

## Core domain
Every transport action is a JOB:
RIDE, DELIVERY, CARGO, CORPORATE_TRIP.

REQUESTED → SEARCHING → ASSIGNED → DRIVER_ARRIVING → IN_PROGRESS → COMPLETED

Terminal states: CANCELLED, REJECTED, EXPIRED.

## Backend
Supabase Postgres + Auth + RLS + Realtime + Edge Functions.
The foundation migration is in `supabase/migrations/`.

## Security
- Browser uses the publishable key only.
- Authorization belongs in RLS and server-side checks.
- Secret/service keys must never ship to the browser.
- Audit events support operational accountability.

## Planned integrations
Maps/geocoding, payments, SMS OTP, push notifications, realtime driver location, dispatch and fraud/risk scoring.