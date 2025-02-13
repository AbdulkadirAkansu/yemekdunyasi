import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/address.dart';
import 'package:flutter/foundation.dart';

class AddressRepository {
  final _supabase = Supabase.instance.client;

  // Adres listesini stream olarak al
  Stream<List<Address>> getAddressesStream() {
    return _supabase
        .from('user_addresses')
        .stream(primaryKey: ['id'])
        .eq('user_id', _supabase.auth.currentUser!.id)
        .order('is_default', ascending: false)
        .map((data) => data.map((json) => Address.fromJson(json)).toList());
  }

  // Varsayılan adresi al
  Future<Address?> getDefaultAddress() async {
    final response = await _supabase
        .from('user_addresses')
        .select()
        .eq('user_id', _supabase.auth.currentUser!.id)
        .eq('is_default', true)
        .maybeSingle();

    return response != null ? Address.fromJson(response) : null;
  }

  // Yeni adres ekle
  Future<Address> addAddress(Address address) async {
    if (address.isDefault) {
      await _clearDefaultAddress();
    }

    final response = await _supabase.from('user_addresses').insert({
      'user_id': _supabase.auth.currentUser!.id,
      'title': address.title,
      'address': address.address,
      'is_default': address.isDefault,
    }).select().single();

    return Address.fromJson(response);
  }

  // Adresi güncelle
  Future<void> updateAddress(Address address) async {
    if (address.isDefault) {
      await _clearDefaultAddress();
    }

    await _supabase.from('user_addresses').update({
      'title': address.title,
      'address': address.address,
      'is_default': address.isDefault,
    }).eq('id', address.id);
  }

  // Adresi sil
  Future<bool> deleteAddress(String id) async {
    try {
      debugPrint('\n====== ADRES SİLME BAŞLATILIYOR ======');
      
      // 1. Kullanıcı kontrolü
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ Kullanıcı oturumu bulunamadı');
        return false;
      }
      debugPrint('1️⃣ Kullanıcı kontrolü OK');
      debugPrint('👤 User ID: ${currentUser.id}');

      // 2. Adres kontrolü
      debugPrint('\n2️⃣ Adres kontrolü başlıyor');
      debugPrint('🎯 Silinecek Adres ID: $id');
      
      final addressCheck = await _supabase
          .from('user_addresses')
          .select()
          .eq('id', id)
          .single();
      
      if (addressCheck == null) {
        debugPrint('❌ Adres bulunamadı');
        return false;
      }

      debugPrint('✅ Adres bulundu:');
      debugPrint('📍 ID: ${addressCheck['id']}');

      // 3. Silme işlemi
      debugPrint('\n3️⃣ Silme işlemi başlıyor');
      await _supabase
          .from('user_addresses')
          .delete()
          .eq('id', id);
      
      debugPrint('✅ Silme işlemi başarılı');
      return true;

    } catch (e) {
      debugPrint('\n❌ HATA OLUŞTU:');
      debugPrint(e.toString());
      return false;
    } finally {
      debugPrint('====== İŞLEM TAMAMLANDI ======\n');
    }
  }

  // Varsayılan adresi değiştir
  Future<void> setDefaultAddress(String id) async {
    await _clearDefaultAddress();
    await _supabase
        .from('user_addresses')
        .update({'is_default': true})
        .eq('id', id);
  }

  // Yardımcı metod: Tüm adreslerin varsayılan özelliğini kaldır
  Future<void> _clearDefaultAddress() async {
    await _supabase
        .from('user_addresses')
        .update({'is_default': false})
        .eq('user_id', _supabase.auth.currentUser!.id);
  }
} 