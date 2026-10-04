# JELAD

Modern Jordanian mobility & logistics platform.

## Current foundation
- Customer web experience
- Driver experience foundation
- Operations foundation
- Responsive mobile-first UI
- Supabase Postgres/Auth foundation with RLS
- Profile bootstrap trigger for new authenticated users
- Vercel deployment configuration

## Supabase
JELAD uses a dedicated Supabase project. The browser only receives the Supabase publishable key; service-role/secret keys are never committed to the repository or exposed to the client.

Core domains currently include:
- profiles
- drivers
- vehicles
- locations
- jobs
- payments
- wallet_ledger
- ratings
- safety_incidents
- audit_events

## Stack
Next.js App Router, React, TypeScript, Tailwind CSS v4, Supabase, pnpm.

## Product direction
JELAD is being built as a unified mobility and logistics platform covering rides, delivery, cargo, corporate trips, driver operations, safety, payments, wallet, dispatch and future intelligence layers.

## Deployment
Production is hosted on Vercel. Environment variables are managed in Vercel and are not stored in Git.
