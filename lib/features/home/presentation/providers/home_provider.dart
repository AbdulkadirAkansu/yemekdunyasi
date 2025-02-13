import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier();
});

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(HomeState()) {
    _loadDefaultAddress();
  }

  final _supabase = Supabase.instance.client;

  Future<void> _loadDefaultAddress() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _supabase
          .from('user_addresses')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_default', true)
          .maybeSingle();

      if (response != null) {
        state = state.copyWith(
          selectedAddress: '${response['title']} - ${response['address']}',
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Adres yükleme hatası: $e',
      );
    }
  }

  void setSelectedTabIndex(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }
}

class HomeState {
  final bool isLoading;
  final String? error;
  final String? selectedAddress;
  final int selectedTabIndex;

  HomeState({
    this.isLoading = false,
    this.error,
    this.selectedAddress,
    this.selectedTabIndex = 0,
  });

  HomeState copyWith({
    bool? isLoading,
    String? error,
    String? selectedAddress,
    int? selectedTabIndex,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }
} 