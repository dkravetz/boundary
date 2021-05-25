begin;

create table auth_oidc_managed_group (
  public_id wt_public_id
    primary key,
  auth_method_id wt_public_id
    not null,
  scope_id wt_scope_id
    not null,
  "name" wt_name,
  description wt_description,
  create_time wt_timestamp,
  update_time wt_timestamp,
  "version" wt_version,
  "filter" wt_bexprfilter
    not null,
  -- Ensure that this managed group relates to an oidc auth method, as opposed
  -- to other types. Including scope ensures that this group is within the same
  -- scope as the auth method.
  constraint auth_oidc_method_fkey
    foreign key (scope_id, auth_method_id) -- fk1
      references auth_oidc_method (scope_id, public_id)
      on delete cascade
      on update cascade,
  -- Ensure it relates to an abstract managed group
  constraint auth_managed_group_fkey
    foreign key (public_id) -- fk2
      references auth_managed_group (public_id)
      on delete cascade
      on update cascade,
  constraint auth_oidc_managed_group_auth_method_id_name_uq
    unique(auth_method_id, name),
  -- QUESTION: is this necessary? It isn't for uniqueness, but maybe for an index to look up via auth method ID?
  constraint auth_oidc_managed_group_auth_method_id_public_id_uq
    unique(auth_method_id, public_id)
);
comment on table auth_oidc_managed_group is
'auth_oidc_managed_group entries are subtypes of auth_managed_group and represent an oidc managed group.';

-- Define the immutable fields of auth_oidc_managed_group
create trigger 
  immutable_columns
before
update on auth_oidc_managed_group
  for each row execute procedure immutable_columns('public_id', 'auth_method_id', 'scope_id', 'create_time');

-- Populate create time on insert
create trigger 
  default_create_time_column
before
insert on auth_oidc_managed_group
  for each row execute procedure default_create_time();

-- Generate update time on update
create trigger
  update_time_column
before
update on auth_oidc_managed_group
  for each row execute procedure update_time_column();

-- Update version when something changes
create trigger 
  update_version_column
after
update on auth_oidc_managed_group
  for each row execute procedure update_version_column();

-- Function to insert into the base table when values are inserted into a
-- concrete type table. This happens before inserts so the foreign keys in the
-- concrete type will be valid.
create or replace function
  insert_managed_group_subtype()
  returns trigger
as $$
begin

  select auth_method.scope_id
    into new.scope_id
  from auth_method
  where auth_method.public_id = new.auth_method_id;

  insert into auth_managed_group
    (public_id, auth_method_id, scope_id)
  values
    (new.public_id, new.auth_method_id, new.scope_id);

  return new;

end;
$$ language plpgsql;

-- Add into the base table when inserting into the concrete table
create trigger
  insert_managed_group_subtype
before insert on auth_oidc_managed_group
  for each row execute procedure insert_managed_group_subtype();

commit;