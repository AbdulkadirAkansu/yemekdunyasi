-- Önce tüm politikaları temizleyelim
drop policy if exists "Profilleri görüntüleme politikası" on profiles;
drop policy if exists "Profil oluşturma politikası" on profiles;
drop policy if exists "Profil güncelleme politikası" on profiles;
drop policy if exists "Enable read access for all users" on profiles;
drop policy if exists "Enable insert access for users based on user_id" on profiles;
drop policy if exists "Enable update access for users based on user_id" on profiles;

-- RLS'yi devre dışı bırakalım
alter table profiles disable row level security;

-- Profiles tablosunu güncelleyelim
alter table profiles 
  add column if not exists first_name text,
  add column if not exists last_name text,
  add column if not exists email_confirmed_at timestamp with time zone;

-- Tetikleyici fonksiyonunu güncelleyelim
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

-- Tetikleyiciyi yeniden oluştur
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user(); 