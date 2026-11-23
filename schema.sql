-- DSD Platform — Supabase schema v2 (roles: admin / organizer). Run once in: Dashboard → SQL Editor
create extension if not exists pgcrypto;

-- Access table: who may use the dashboard, and with which role
create table if not exists public.dsd_admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  email      text,
  role       text not null default 'admin' check (role in ('admin','organizer')),
  created_at timestamptz not null default now()
);

create table if not exists public.dsd_applicants (
  id            uuid primary key default gen_random_uuid(),
  name          text not null check (char_length(name) between 3 and 120),
  email         text not null default '' check (char_length(email) <= 160),
  phone         text not null default '' check (char_length(phone) <= 30),
  org           text not null default '' check (char_length(org) <= 200),
  role          text not null check (role in ('workshop','guest','exhibitor','vip','jury')),
  status        text not null default 'pending' check (status in ('pending','approved','rejected')),
  details       jsonb not null default '{}',
  checked_in_at timestamptz,
  created_at    timestamptz not null default now()
);
create unique index if not exists dsd_applicants_email_uq on public.dsd_applicants (lower(email)) where email <> '';

create table if not exists public.dsd_staff (
  id uuid primary key default gen_random_uuid(),
  name text not null, email text not null, role text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.dsd_documents (
  id uuid primary key default gen_random_uuid(),
  ref text not null,
  type text not null check (type in ('b','c')),
  code text not null unique,
  name text not null, role text not null, org text not null default '',
  event_date text not null default '',
  revoked boolean not null default false,
  created_at timestamptz not null default now(),
  unique (ref, type)
);

-- Role helpers
create or replace function public.dsd_my_role() returns text
language sql security definer stable set search_path = public as
$$ select role from public.dsd_admins where user_id = auth.uid() $$;
create or replace function public.dsd_is_admin() returns boolean
language sql security definer stable set search_path = public as
$$ select exists (select 1 from public.dsd_admins where user_id = auth.uid() and role = 'admin') $$;
create or replace function public.dsd_is_staff() returns boolean
language sql security definer stable set search_path = public as
$$ select exists (select 1 from public.dsd_admins where user_id = auth.uid()) $$;
revoke all on function public.dsd_my_role(), public.dsd_is_admin(), public.dsd_is_staff() from public;
grant execute on function public.dsd_my_role(), public.dsd_is_admin(), public.dsd_is_staff() to anon, authenticated;

-- Admin-only: grant/change a role for a user that already exists in Authentication
create or replace function public.dsd_grant_access(p_email text, p_role text) returns void
language plpgsql security definer set search_path = public, auth as $$
declare uid uuid;
begin
  if not public.dsd_is_admin() then raise exception 'forbidden'; end if;
  if p_role not in ('admin','organizer') then raise exception 'bad_role'; end if;
  select id into uid from auth.users where lower(email) = lower(p_email);
  if uid is null then raise exception 'user_not_found'; end if;
  insert into public.dsd_admins (user_id, email, role) values (uid, lower(p_email), p_role)
  on conflict (user_id) do update set role = excluded.role, email = excluded.email;
end $$;
revoke all on function public.dsd_grant_access(text, text) from public;
grant execute on function public.dsd_grant_access(text, text) to authenticated;

-- Public QR verification
create or replace function public.dsd_verify_document(p_type text, p_code text)
returns table (name text, role text, org text, event_date text, revoked boolean)
language sql security definer stable set search_path = public as
$$ select d.name, d.role, d.org, d.event_date, d.revoked from public.dsd_documents d
   where d.type = p_type and d.code = p_code limit 1 $$;
revoke all on function public.dsd_verify_document(text, text) from public;
grant execute on function public.dsd_verify_document(text, text) to anon, authenticated;

-- Row Level Security
alter table public.dsd_admins     enable row level security;
alter table public.dsd_applicants enable row level security;
alter table public.dsd_staff      enable row level security;
alter table public.dsd_documents  enable row level security;

create policy admins_self_read  on public.dsd_admins for select to authenticated using (user_id = auth.uid());
create policy admins_admin_all  on public.dsd_admins for all    to authenticated using (public.dsd_is_admin()) with check (public.dsd_is_admin());

create policy applicants_public_insert on public.dsd_applicants for insert to anon, authenticated
  with check (status = 'pending' and role in ('workshop','guest','exhibitor'));
create policy applicants_admin_insert  on public.dsd_applicants for insert to authenticated with check (public.dsd_is_admin());
create policy applicants_staff_select  on public.dsd_applicants for select to authenticated using (public.dsd_is_staff());
create policy applicants_staff_update  on public.dsd_applicants for update to authenticated using (public.dsd_is_staff()) with check (public.dsd_is_staff());
create policy applicants_admin_delete  on public.dsd_applicants for delete to authenticated using (public.dsd_is_admin());

create policy staff_staff_select on public.dsd_staff for select to authenticated using (public.dsd_is_staff());
create policy staff_admin_write  on public.dsd_staff for all    to authenticated using (public.dsd_is_admin()) with check (public.dsd_is_admin());

create policy documents_staff_all on public.dsd_documents for all to authenticated using (public.dsd_is_staff()) with check (public.dsd_is_staff());
