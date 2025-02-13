import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/address.dart';
import 'package:flutter/foundation.dart';
import '../../../home/presentation/viewmodels/home_view_model.dart';

// Repository provider
final addressRepositoryProvider = Provider((ref) => AddressRepository());

// ViewModel provider
final addressViewModelProvider = StateNotifierProvider<AddressViewModel, AsyncValue<List<Address>>>((ref) {
  return AddressViewModel(ref, ref.read(addressRepositoryProvider));
});

// Repository class for data access
class AddressRepository {
  final _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> fetchAddresses() async {
    final response = await _supabase
        .from('user_addresses')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<bool> deleteAddress(String id) async {
  try {
    // Önce mevcut kullanıcı ID'sini yazdıralım
    final currentUser = _supabase.auth.currentUser;
    debugPrint('\n👤 Mevcut Kullanıcı Bilgileri:');
    debugPrint('ID: ${currentUser?.id}');
    debugPrint('Email: ${currentUser?.email}');
    
    // Silinecek adresin bilgilerini kontrol edelim
    final addressData = await _supabase
        .from('user_addresses')
        .select('user_id, title')
        .eq('id', id)
        .single();
    
    debugPrint('\n📍 Silinecek Adres Bilgileri:');
    debugPrint('Adres ID: $id');
    debugPrint('Kullanıcı ID: ${addressData['user_id']}');
    debugPrint('Başlık: ${addressData['title']}');
    
    // ID'leri karşılaştıralım
    if (currentUser?.id != addressData['user_id']) {
      debugPrint('\n❌ HATA: Kullanıcı ID\'leri eşleşmiyor!');
      debugPrint('Auth ID: ${currentUser?.id}');
      debugPrint('Adres user_id: ${addressData['user_id']}');
      return false;
    }

    // Silme işlemini gerçekleştirelim
    await _supabase
        .from('user_addresses')
        .delete()
        .eq('id', id)
        .eq('user_id', currentUser!.id);
    
    return true;
  } catch (e) {
    debugPrint('\n❌ Silme Hatası: $e');
    return false;
  }
}


  Future<void> updateDefaultStatus(String userId, {required bool setAllFalse, String? newDefaultId}) async {
    if (setAllFalse) {
      await _supabase
          .from('user_addresses')
          .update({'is_default': false})
          .eq('user_id', userId);
    }
    
    if (newDefaultId != null) {
      await _supabase
          .from('user_addresses')
          .update({'is_default': true})
          .eq('id', newDefaultId);
    }
  }

  Future<void> addNewAddress(Map<String, dynamic> addressData) async {
    await _supabase
        .from('user_addresses')
        .insert(addressData);
  }

  Future<void> updateAddress(String id, Map<String, dynamic> data) async {
    await _supabase
        .from('user_addresses')
        .update(data)
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<bool> deleteAllAddresses() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('\n❌ HATA: Kullanıcı oturum açık değil');
        return false;
      }

      final response = await _supabase
          .from('user_addresses')
          .select()
          .eq('user_id', currentUser.id);

      if (response.isEmpty) {
        debugPrint('\n📋 Bilgiler: Tüm adresler zaten silinmiş');
        return true;
      }

      for (var address in response) {
        await deleteAddress(address['id']);
      }

      return true;
    } catch (e) {
      debugPrint('\n❌ Tüm adresler silinirken bir hata oluştu: $e');
      return false;
    }
  }
}

// ViewModel class
class AddressViewModel extends StateNotifier<AsyncValue<List<Address>>> {
  final Ref _ref;
  final AddressRepository _repository;
  
  AddressViewModel(this._ref, this._repository) : super(const AsyncValue.loading()) {
    loadAddresses();
  }

  Future<void> loadAddresses() async {
    try {
      state = const AsyncValue.loading();
      final response = await _repository.fetchAddresses();
      debugPrint('📥 Adresler yüklendi: $response');
      
      final addresses = response.map((json) => Address.fromJson(json)).toList();
      state = AsyncValue.data(addresses);
    } catch (e, stack) {
      debugPrint('❌ Adres yükleme hatası: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addAddress(
    String title,
    String address,
    bool isDefault, {
    String? city,
    String? district,
  }) async {
    try {
      final userId = _repository._userId;
      final addressData = {
        'user_id': userId,
        'title': title,
        'address': address,
        'is_default': isDefault,
        'created_at': DateTime.now().toIso8601String(),
        'lat': 0,
        'lng': 0,
        'city': city,
        'district': district,
      };

      if (isDefault) {
        await _repository.updateDefaultStatus(userId, setAllFalse: true);
      }

      await _repository.addNewAddress(addressData);
      await _refreshData();
    } catch (e) {
      debugPrint('❌ Adres ekleme hatası: $e');
      rethrow;
    }
  }

  Future<void> updateAddress(
    String id,
    String title,
    String address,
    bool isDefault, {
    String? city,
    String? district,
  }) async {
    try {
      final userId = _repository._userId;
      
      if (isDefault) {
        await _repository.updateDefaultStatus(userId, setAllFalse: true);
      }

      await _repository.updateAddress(id, {
        'title': title,
        'address': address,
        'is_default': isDefault,
        'city': city,
        'district': district,
      });

      await _refreshData();
    } catch (e) {
      debugPrint('❌ Adres güncelleme hatası: $e');
      rethrow;
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      debugPrint('\n🔄 [VM] ====== ADRES SİLME İŞLEMİ BAŞLATILIYOR ======');
      debugPrint('📍 [VM] Silinecek adres ID: $id');
      
      // Önce mevcut state'i yedekleyelim
      final currentState = state;
      state = const AsyncValue.loading();
      
      // Repository'de silme işlemini gerçekleştir
      debugPrint('\n🗑️ [VM] REPOSITORY\'DE SİLME İŞLEMİ BAŞLATILIYOR');
      final success = await _repository.deleteAddress(id);
      debugPrint('📋 [VM] Silme işlemi sonucu: ${success ? "Başarılı" : "Başarısız"}');

      if (!success) {
        // Silme başarısız olursa önceki state'e geri dön
        state = currentState;
        throw Exception('Adres silinirken bir hata oluştu');
      }

      // Silme başarılı olduysa state'i güncelle
      if (state.hasValue && state.value != null) {
        final updatedAddresses = state.value!.where((address) => address.id != id).toList();
        
        // Varsayılan adres kontrolü
        final deletedAddress = state.value!.firstWhere((address) => address.id == id, orElse: () => Address.empty());
        if (deletedAddress.isDefault && updatedAddresses.isNotEmpty) {
          debugPrint('\n⭐ [VM] VARSAYILAN ADRES GÜNCELLEME AŞAMASI');
          debugPrint('📊 [VM] Kalan adres sayısı: ${updatedAddresses.length}');
          
          await _repository.updateDefaultStatus(
            _repository._userId,
            setAllFalse: false,
            newDefaultId: updatedAddresses.first.id,
          );
          debugPrint('✅ [VM] Yeni varsayılan adres ayarlandı');
        }

        // State'i güncelle
        state = AsyncValue.data(updatedAddresses);
      }

      // Verileri yenile
      debugPrint('\n🔄 [VM] VERİLER YENİLENİYOR');
      await _refreshData();
      debugPrint('✅ [VM] Veriler güncellendi');
      debugPrint('====== İŞLEM TAMAMLANDI ======\n');
    } catch (e, stack) {
      debugPrint('\n❌ [VM] HATA OLUŞTU');
      debugPrint('📍 [VM] Hata mesajı: $e');
      debugPrint('📍 [VM] Stack trace: $stack');
      rethrow;
    }
  }

  Future<void> setDefaultAddress(String id) async {
    try {
      state = const AsyncValue.loading();
      await _repository.updateDefaultStatus(
        _repository._userId,
        setAllFalse: true,
        newDefaultId: id,
      );
      await _refreshData();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteAllAddresses() async {
    try {
      debugPrint('\n🔄 [VM] ====== TÜM ADRESLERİ SİLME İŞLEMİ BAŞLATILIYOR ======');
      
      // Önce mevcut state'i yedekleyelim
      final currentState = state;
      state = const AsyncValue.loading();
      
      // Repository'de silme işlemini gerçekleştir
      final success = await _repository.deleteAllAddresses();
      
      if (!success) {
        // Silme başarısız olursa önceki state'e geri dön
        state = currentState;
        throw Exception('Adresler silinirken bir hata oluştu');
      }

      // State'i güncelle
      state = const AsyncValue.data([]);
      
      // Verileri yenile
      await _refreshData();
      
      debugPrint('✅ [VM] Tüm adresler başarıyla silindi');
    } catch (e, stack) {
      debugPrint('\n❌ [VM] HATA OLUŞTU');
      debugPrint('📍 [VM] Hata mesajı: $e');
      debugPrint('📍 [VM] Stack trace: $stack');
      rethrow;
    }
  }

  Future<void> _refreshData() async {
    await loadAddresses();
    await _ref.read(homeProvider.notifier).refreshDefaultAddress();
  }
} 