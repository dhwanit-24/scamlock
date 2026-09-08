-- Security hardening
--
-- #2: Prevent direct profile updates from bypassing the audited
-- update_user_status_with_audit() function.
drop policy if exists "Admins can update profiles"
on public.profiles;

-- #4: Lock the trigger function's search_path.
alter function public.handle_tracked_people_updated_at()
set search_path = '';

-- #6: Prevent anonymous execution of profile/firm-detail
-- SECURITY DEFINER functions.
revoke execute on function public.get_current_profile() from anon;

revoke execute on function public.get_locking_firm_details(uuid, uuid)
from anon;