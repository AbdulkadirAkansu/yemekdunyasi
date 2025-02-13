-- Önce tüm politikaları temizle
drop policy if exists "Users can view their own addresses" on user_addresses;
drop policy if exists "Users can insert their own addresses" on user_addresses;
drop policy if exists "Users can update their own addresses" on user_addresses;
drop policy if exists "Users can delete their own addresses" on user_addresses;
drop policy if exists "Enable read access for authenticated users" on user_addresses;
drop policy if exists "Enable insert access for authenticated users" on user_addresses;
drop policy if exists "Enable update access for authenticated users" on user_addresses;
drop policy if exists "Enable delete access for authenticated users" on user_addresses;

-- RLS'yi etkinleştir
alter table user_addresses enable row level security;

-- Yeni politikaları oluştur
create policy "Users can view their own addresses"
on user_addresses for select
using (auth.uid() = user_id);

create policy "Users can insert their own addresses"
on user_addresses for insert
with check (auth.uid() = user_id);

create policy "Users can update their own addresses"
on user_addresses for update
using (auth.uid() = user_id);

create policy "Users can delete their own addresses"
on user_addresses for delete
using (auth.uid() = user_id);

-- Create audit log table
create table if not exists address_audit_logs (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references auth.users(id),
    address_id uuid,
    action text not null,
    old_data jsonb,
    created_at timestamptz default now()
);

-- Güvenli silme fonksiyonunu güncelle
create or replace function delete_address_secure(address_id uuid)
returns boolean
language plpgsql
security definer set search_path = public
as $$
declare
    target_address record;
    current_user_id uuid;
begin
    -- Mevcut kullanıcıyı al
    current_user_id := auth.uid();
    
    -- Kullanıcı oturum kontrolü
    if current_user_id is null then
        raise exception 'Oturum açmanız gerekiyor';
    end if;
    
    -- Adres detaylarını al
    select * into target_address
    from user_addresses
    where id = address_id;
    
    -- Adres kontrolü
    if target_address is null then
        return false;
    end if;
    
    -- Adresi sil
    delete from user_addresses
    where id = address_id;
    
    return true;
exception
    when others then
        return false;
end;
$$; 