# DSD Platform — final package (AR / FR / EN + Supabase)

No demo data and no demo login are included. Everything starts empty.

## Files to upload to the ROOT of your static host (Vercel / Netlify / GitHub Pages)
index.html · app.js · styles.css · config.js · favicon.jpg (your icon)

## Setup checklist
1. Supabase → SQL Editor → run `schema.sql`.
2. Run `seed_admin.sql` → principal admin admin@dsd.dz (change the password after the first login).
3. Edit `config.js` → paste Project URL + `anon` key (never the service_role key).
4. Authentication → URL Configuration → add your site address.
5. Upload the files, open the site → "Organizers" → sign in.
6. In the site (Certificates tab) enter the event date before generating certificates.

## If you ever tested with fake registrations
Run `reset.sql` in the SQL Editor: it empties registrations, staff and issued documents (accounts are kept).

## Roles
Admin: everything. Organizer: registrants (approve/reject), check-in, certificates & badges, staff (read-only).
Add an organizer: create the user in Authentication → Users (Auto Confirm), then in the site: Access & roles → Grant access.

## Editing the code
`dsd-source.zip` → `npm i` → `npm run build` (output in `dist/`).


All database objects are prefixed `dsd_` (dsd_applicants, dsd_documents, …) so they can share a Supabase project with other apps without collisions. `reset.sql` only touches the dsd_ tables.
If the project is shared with another app, do NOT disable public sign-ups in Authentication (it would affect that app).
