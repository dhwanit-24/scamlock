-- Fix 1: handle_first_lock_for_person never fired because the AFTER INSERT
-- trigger's existence check included the row that just triggered it.
-- Exclude new.id so the check correctly reflects "no OTHER lock existed before this one".
create or replace function handle_first_lock_for_person()
returns trigger
security definer
set search_path = public
language plpgsql
as $$
begin
  if not exists (
    select 1 from public.person_locks
    where person_id = new.person_id
      and id <> new.id
  ) then
    update public.tracked_people
    set initially_locked_by = new.locked_by,
        locked_on = now()
    where id = new.person_id;
  end if;
  return new;
end;
$$;

-- Fix 2: log_person_lock_event_trigger currently fires on every UPDATE to
-- person_locks, even if status didn't change.
drop trigger if exists log_person_lock_event_trigger on person_locks;

create trigger log_person_lock_event_trigger
after insert on person_locks
for each row
execute function log_person_lock_event();

create trigger log_person_lock_event_update_trigger
after update on person_locks
for each row
when (old.status is distinct from new.status)
execute function log_person_lock_event();
