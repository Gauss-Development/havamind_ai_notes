-- Close the INSERT escalation hole for the server-owned subscription tier.
--
-- 20260621_subscription_tier_server_owned.sql only guards BEFORE UPDATE, so an
-- authenticated client could INSERT its own profile row with
-- subscription_tier='pro' before the app creates it (the INSERT RLS policy
-- checks only auth.uid() = id, not the tier value). Guard INSERT as well.
--
-- Service-role writers (the revenuecat-webhook Edge Function) run with
-- auth.role() = 'service_role' and are intentionally exempt, so they remain
-- the only path that can grant a paid tier.

create or replace function public.prevent_client_subscription_tier_insert()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if auth.role() = 'authenticated'
     and new.subscription_tier is distinct from 'free' then
    raise exception 'subscription_tier is server-owned'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_prevent_client_subscription_tier_insert
  on public.profiles;

create trigger profiles_prevent_client_subscription_tier_insert
before insert on public.profiles
for each row
execute function public.prevent_client_subscription_tier_insert();
