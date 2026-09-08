-- 1. Close the admin-bypass hole: require caller to be an active admin
create or replace function public.update_user_status_with_audit(
  p_user_id uuid,
  p_new_status text,
  p_action text
)
returns void
language plpgsql
security definer
set search_path to ''
as $func$
begin
  if not exists (
    select 1 from public.profiles
    where id = auth.uid()
      and app_role = 'admin'
      and account_status = 'active'
  ) then
    raise exception 'Only active admins can update user status';
  end if;

  update public.profiles
  set account_status = p_new_status
  where id = p_user_id;

  insert into public.admin_actions (
    admin_id,
    target_user_id,
    action,
    note
  ) values (
    auth.uid(),
    p_user_id,
    p_action,
    null
  );
end;
$func$;

drop policy if exists "Authenticated users can view all profiles" on public.profiles;

create policy "Admins can view all profiles"
on public.profiles
for select
to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.app_role = 'admin'
  )
);

create policy "Active members can view other active profiles"
on public.profiles
for select
to authenticated
using (
  account_status = 'active'
  and exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.account_status = 'active'
  )
);

revoke execute on function public.create_profile_for_new_user() from anon, authenticated;
revoke execute on function public.handle_first_lock_for_person() from anon, authenticated;
revoke execute on function public.handle_person_lock_changes() from anon, authenticated;
revoke execute on function public.log_person_lock_event() from anon, authenticated;
