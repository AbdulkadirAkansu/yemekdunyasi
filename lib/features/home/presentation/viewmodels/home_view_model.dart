import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

// State sınıfı
class HomeState {
  final bool isLoading;
  final String? selectedAddress;
  final int selectedTabIndex;

  const HomeState({
    this.isLoading = false,
    this.selectedAddress,
    this.selectedTabIndex = 0,
  });

  HomeState copyWith({
    bool? isLoading,
    String? selectedAddress,
    int? selectedTabIndex,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }
}

// StateNotifier
class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(const HomeState()) {
    _loadDefaultAddress();
  }

  final _supabase = Supabase.instance.client;

  void setSelectedTabIndex(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }

  Future<void> _loadDefaultAddress() async {
    state = state.copyWith(isLoading: true);
    try {
      debugPrint('Varsayılan adres yükleniyor...');
      final response = await _supabase
          .from('user_addresses')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_default', true)
          .maybeSingle();

      debugPrint('Varsayılan adres yanıtı: $response');

      if (response != null) {
        final address = '${response['title']} - ${response['address']}';
        debugPrint('Yeni varsayılan adres: $address');
        state = state.copyWith(
          selectedAddress: address,
          isLoading: false,
        );
      } else {
        debugPrint('Varsayılan adres bulunamadı');
        state = state.copyWith(
          selectedAddress: null,
          isLoading: false,
        );
      }
    } catch (e) {
      debugPrint('Varsayılan adres yükleme hatası: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  // Adreslerde değişiklik olduğunda bu metodu çağır
  Future<void> refreshDefaultAddress() async {
    await _loadDefaultAddress();
  }
}

// Provider
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier();
}); 