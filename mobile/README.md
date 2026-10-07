# JELAD Mobile

Flutter workspace for the JELAD Customer and Driver apps.

## Apps
- customer: passenger, delivery, cargo, live tracking and safety
- driver: driver verification, availability, jobs, trip lifecycle, navigation and safety

Both apps use the same Supabase project and shared domain/service packages.

## Status
Foundation scaffold created. Backend integration uses JELAD RPCs and RLS; no service-role credentials belong in the mobile apps.


## Build validation
The CI workflow generates native Android/iOS platform files, validates both apps, and publishes Android debug APK artifacts. Production release builds must provide `SUPABASE_URL` and the project's publishable key through secure CI variables.
