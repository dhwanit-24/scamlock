create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = ''
stable
as $func$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and app_role = 'admin'
  );
$func$;

create or replace function public.is_active_account()
returns boolean
language sql
security definer
set search_path = ''
stable
as $func$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and account_status = 'active'
  );
$func$;

revoke execute on function public.is_admin() from public, anon;
revoke execute on function public.is_active_account() from public, anon;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_active_account() to authenticated;

drop policy if exists "Admins can view all profiles" on public.profiles;
create policy "Admins can view all profiles" on public.profiles
for select to authenticated
using (public.is_admin());

drop policy if exists "Active members can view other active profiles" on public.profiles;
create policy "Active members can view other active profiles" on public.profiles
for select to authenticated
using (account_status = 'active' and public.is_active_account());

drop policy if exists "Admins can update profiles" on public.profiles;
create policy "Admins can update profiles" on public.profiles
for update to authenticated
using (public.is_admin());

drop policy if exists "Admins can insert admin actions" on public.admin_actions;
create policy "Admins can insert admin actions" on public.admin_actions
for insert to authenticated
with check (public.is_admin());

drop policy if exists "Admins can read all admin actions" on public.admin_actions;
create policy "Admins can read all admin actions" on public.admin_actions
for select to authenticated
using (public.is_admin());

drop policy if exists "Active members can view lock events" on public.person_lock_events;
create policy "Active members can view lock events" on public.person_lock_events
for select to authenticated
using (public.is_active_account());

drop policy if exists "Active firm can manage own locks" on public.person_locks;
create policy "Active firm can manage own locks" on public.person_locks
for insert to authenticated
with check (locked_by = auth.uid() and public.is_active_account());

drop policy if exists "Active firm can update own locks" on public.person_locks;
create policy "Active firm can update own locks" on public.person_locks
for update to authenticated
using (locked_by = auth.uid() and public.is_active_account())
with check (locked_by = auth.uid() and public.is_active_account());

drop policy if exists "Active members can view person locks" on public.person_locks;
create policy "Active members can view person locks" on public.person_locks
for select to authenticated
using (public.is_active_account());

drop policy if exists "Active members can create tracked people" on public.tracked_people;
create policy "Active members can create tracked people" on public.tracked_people
for insert to authenticated
with check (public.is_active_account());

drop policy if exists "Active members can view tracked people" on public.tracked_people;
create policy "Active members can view tracked people" on public.tracked_people
for select to authenticated
using (public.is_active_account());
