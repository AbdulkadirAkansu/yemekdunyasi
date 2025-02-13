import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Giriş denemesi: $email');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw const AuthException('Giriş başarısız oldu');
      }

      debugPrint('Giriş başarılı: ${response.user?.id} - ${response.user?.email}');
    } catch (e) {
      debugPrint('Giriş hatası: $e');
      throw AuthException(e.toString());
    }
  }

  Future<void> signInWithOtp({required String email}) async {
    try {
      debugPrint('OTP gönderiliyor: $email');
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      debugPrint('OTP başarıyla gönderildi');
    } catch (e) {
      debugPrint('OTP hatası: $e');
      throw AuthException(e.toString());
    }
  }
} 