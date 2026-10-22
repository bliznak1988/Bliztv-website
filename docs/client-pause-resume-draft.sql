-- BLiZ TV client pause/resume: DRAFT migration, NOT automatically applied.
-- IMPORTANT: adapt activation table/column names to deployed schema before executing.
-- Store customer metadata separately from IPTV credentials.
create table if not exists public.bliztv_client_controls (
  activation_code_id text primary key,
  customer_name text not null default '',
  admin_note text not null default '',
  access_status text not null default 'active'
    check (access_status in ('active','paused')),
  updated_at timestamptz not null default now(),
  updated_by uuid
);
alter table public.bliztv_client_controls enable row level security;
-- No public RLS policies: clients must never read notes or modify status.
-- Only trusted Edge Functions using service-role credentials can update this table.
create index if not exists bliztv_client_controls_status_idx
  on public.bliztv_client_controls(access_status);
-- REQUIRED BACKEND FOLLOW-UP:
-- 1. Add authenticated super-admin-only actions: client_controls_list,
--    client_controls_update (name, note), client_controls_pause, client_controls_resume.
-- 2. Verify ADMIN_ID from auth token server-side; never trust client-supplied admin IDs.
-- 3. On every activation check, validate server-side activation status. A paused
--    code must be rejected even when it was previously activated.
-- 4. Android APK must poll a dedicated lightweight device status endpoint
--    (e.g. every 30 seconds while active), and block playback/show activation
--    screen on paused. Local remembered activation must not bypass server status.
-- 5. Resume must restore existing code without generating a new one.
-- 6. Offline policy must be specified: immediate kick-out is impossible offline.
-- 7. Check existing activation table/code ID representation before linking records.
