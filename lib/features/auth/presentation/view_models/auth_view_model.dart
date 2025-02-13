import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/exceptions/auth_exception.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AsyncValue<void>>((ref) {
  return AuthViewModel(ref.read(authRepositoryProvider));
});

class AuthViewModel extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  AuthViewModel(this._repository) : super(const AsyncValue.data(null));

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String fullName,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      await _repository.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        fullName: fullName,
      );
      
      state = const AsyncValue.data(null);
      
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      await _repository.signIn(
        email: email,
        password: password,
      );
      
      state = const AsyncValue.data(null);
      
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      state = const AsyncValue.loading();
      await _repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> verifyOTP({
    required String email,
    required String token,
  }) async {
    try {
      state = const AsyncValue.loading();
      await _repository.verifyOTP(
        email: email,
        token: token,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  bool isAuthenticated() => _repository.isLoggedIn;
} 