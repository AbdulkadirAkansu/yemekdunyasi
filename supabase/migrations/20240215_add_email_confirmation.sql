-- Profiles tablosuna email_confirmed_at sütunu ekle
alter table profiles
add column if not exists email_confirmed_at timestamp with time zone;

-- Trigger fonksiyonunu güncelle
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    first_name,
    last_name,
    email,
    full_name,
    created_at,
    updated_at,
    email_confirmed_at
  )
  values (
    new.id,
    new.raw_user_meta_data->>'first_name',
    new.raw_user_meta_data->>'last_name',
    new.email,
    concat(
      coalesce(new.raw_user_meta_data->>'first_name', ''),
      ' ',
      coalesce(new.raw_user_meta_data->>'last_name', '')
    ),
    now(),
    now(),
    case
      when (new.email_confirmed_at is not null) then new.email_confirmed_at
      else null
    end
  );
  return new;
end;
$$; 