-- Creates the principal admin account (admin@dsd.dz / dsd2026) with role 'admin'.
-- Run AFTER schema.sql. If it errors, create the user in Authentication → Users (Auto Confirm) and run the last statement only.
-- CHANGE THE PASSWORD after the first login: it is weak and was shown publicly.
with u as (
  insert into auth.users (instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,
    raw_app_meta_data,raw_user_meta_data,created_at,updated_at,
    confirmation_token,email_change,email_change_token_new,recovery_token)
  values ('00000000-0000-0000-0000-000000000000',gen_random_uuid(),'authenticated','authenticated',
    'admin@dsd.dz',crypt('dsd2026',gen_salt('bf')),now(),
    '{"provider":"email","providers":["email"]}','{}',now(),now(),'','','','')
  returning id,email
), i as (
  insert into auth.identities (id,user_id,provider_id,identity_data,provider,last_sign_in_at,created_at,updated_at)
  select gen_random_uuid(),id,id::text,jsonb_build_object('sub',id::text,'email',email,'email_verified',true),'email',now(),now(),now() from u
)
insert into public.dsd_admins (user_id,email,role) select id,email,'admin' from u;

-- Fallback (user already created from the dashboard):
-- insert into public.dsd_admins (user_id,email,role) select id,email,'admin' from auth.users where email='admin@dsd.dz';
