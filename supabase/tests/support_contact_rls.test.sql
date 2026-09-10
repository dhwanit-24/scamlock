begin;

select plan(4);

select ok(
  row_security_active('public.support_contact'::regclass),
  'support_contact has RLS enabled'
);

select ok(
  has_table_privilege('anon', 'public.support_contact', 'select'),
  'anon can read the public support contact'
);

select ok(
  not has_table_privilege('anon', 'public.support_contact', 'insert, update, delete'),
  'anon cannot change the support contact'
);

select ok(
  not has_table_privilege('authenticated', 'public.support_contact', 'insert, update, delete'),
  'authenticated users cannot change the support contact'
);

select * from finish();

rollback;