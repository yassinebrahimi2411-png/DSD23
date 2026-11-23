-- FRESH START: deletes every registration, staff member and issued document.
-- Run in Supabase → SQL Editor only when you really want to wipe the data. Cannot be undone.
truncate table public.dsd_documents, public.dsd_staff, public.dsd_applicants restart identity;
-- (admins and the schema are kept)
