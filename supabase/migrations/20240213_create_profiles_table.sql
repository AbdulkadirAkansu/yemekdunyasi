-- Önce mevcut tabloyu ve politikaları temizle
drop policy if exists "Public profiles are viewable by everyone" on profiles;
drop policy if exists "Users can insert their own profile" on profiles;
drop policy if exists "Users can update own profile" on profiles;
drop policy if exists "Enable delete for users based on user_id" on profiles;

-- Tabloyu ve bağımlılıkları sil
drop table if exists profiles cascade;

-- Yeni profiles tablosunu oluştur
create table profiles (
    id uuid references auth.users on delete cascade primary key,
    full_name text,
    email text unique,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS'yi etkinleştir
alter table profiles enable row level security;

-- Profil politikalarını oluştur
create policy "Profiller herkese açık görünür"
on profiles for select
using (true);

create policy "Kullanıcılar kendi profillerini oluşturabilir"
on profiles for insert
with check (auth.uid() = id);

create policy "Kullanıcılar kendi profillerini güncelleyebilir"
on profiles for update
using (auth.uid() = id);

-- Tetikleyici fonksiyonu
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
    insert into public.profiles (id, full_name, email)
    values (new.id, new.raw_user_meta_data->>'full_name', new.email);
    return new;
end;
$$;

-- Tetikleyiciyi oluştur
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure public.handle_new_user();

-- Recipes tablosunu yeniden oluştur
create table if not exists recipes (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references profiles(id) on delete cascade,
    title text not null,
    description text,
    ingredients jsonb,
    instructions jsonb,
    cooking_time interval,
    serving_size integer,
    difficulty text,
    category text,
    image_url text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
); 