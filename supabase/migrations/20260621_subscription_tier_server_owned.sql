-- Keep subscription tier server-owned.
--
-- Client-side RevenueCat state is useful for UI, but Edge Functions use
-- profiles.subscription_tier for quota/payment gates. Authenticated clients
-- must not be able to promote themselves by updating this column directly.

create or replace function public.prevent_client_subscription_tier_update()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if auth.role() = 'authenticated'
     and new.subscription_tier is distinct from old.subscription_tier then
    raise exception 'subscription_tier is server-owned'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_prevent_client_subscription_tier_update
  on public.profiles;

create trigger profiles_prevent_client_subscription_tier_update
before update on public.profiles
for each row
execute function public.prevent_client_subscription_tier_update();
