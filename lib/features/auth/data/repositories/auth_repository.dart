import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:yemekdunyasi/features/auth/data/exceptions/auth_exception.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  // Rate limit için son istek zamanını tutacağız
  static DateTime? _lastOtpRequestTime;
  static const _otpCooldown = Duration(minutes: 1); // 1 dakika bekleme süresi

  // Email kontrolü - Yeni metod
  Future<bool> isEmailRegistered(String email) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('email')
          .eq('email', email)
          .maybeSingle();
      
      if (kDebugMode) {
        print('📧 [AUTH] Email kontrol sonucu: $response');
      }

      return response != null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AUTH] Email kontrol hatası: $e');
      }
      return false;
    }
  }

  // Kayıt olma
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String fullName,
  }) async {
    try {
      debugPrint('\n====== KAYIT İŞLEMİ BAŞLATILIYOR ======');
      debugPrint('📧 Email: $email');
      debugPrint('👤 Ad: $firstName');
      debugPrint('👤 Soyad: $lastName');

      // Önce kullanıcıyı oluştur
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'full_name': fullName,
        },
      );

      if (response.user != null) {
        debugPrint('✅ Kullanıcı oluşturuldu');
        debugPrint('👤 Kullanıcı ID: ${response.user!.id}');
        
        // Profiles tablosuna kullanıcı bilgilerini ekle
        await _supabase.from('profiles').upsert({
          'id': response.user!.id,
          'first_name': firstName,
          'last_name': lastName,
          'full_name': fullName,
          'email': email,
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ Profil bilgileri kaydedildi');
      }

      debugPrint('📨 Doğrulama e-postası gönderildi');

    } catch (e) {
      debugPrint('\n❌ KAYIT HATASI: $e');
      if (e.toString().contains('User already registered')) {
        throw AuthException(
          message: 'Bu e-posta adresi ile daha önce kayıt olunmuş',
          statusCode: '400',
          errorCode: 'user_already_registered'
        );
      } else if (e.toString().contains('Invalid email')) {
        throw AuthException(
          message: 'Geçerli bir e-posta adresi girin',
          statusCode: '400',
          errorCode: 'invalid_email'
        );
      }
      throw AuthException(
        message: 'Kayıt işlemi sırasında bir hata oluştu. Lütfen tekrar deneyin.',
        statusCode: '500',
        errorCode: 'unknown_error'
      );
    } finally {
      debugPrint('====== İŞLEM TAMAMLANDI ======\n');
    }
  }

  // Giriş yapma
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('\n====== GİRİŞ İŞLEMİ BAŞLATILIYOR ======');
      debugPrint('📧 Email: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AuthException(
          message: 'Giriş başarısız oldu',
          statusCode: '400',
          errorCode: 'login_failed'
        );
      }

      debugPrint('✅ Giriş başarılı');
      debugPrint('👤 Kullanıcı ID: ${response.user!.id}');
      debugPrint('📧 Email: ${response.user!.email}');

    } catch (e) {
      debugPrint('\n❌ GİRİŞ HATASI: $e');
      if (e.toString().contains('Invalid login credentials')) {
        throw AuthException(
          message: 'Email veya şifre hatalı',
          statusCode: '400',
          errorCode: 'invalid_credentials'
        );
      }
      rethrow;
    } finally {
      debugPrint('====== İŞLEM TAMAMLANDI ======\n');
    }
  }

  // Google ile Giriş
  Future<AuthResponse> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('🔄 [AUTH] Google giriş başlatılıyor...');
      }

      // 1️⃣ Google Sign-In
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google girişi iptal edildi');
      }

      if (kDebugMode) {
        print('✅ [AUTH] Google hesabı seçildi: ${googleUser.email}');
      }

      // 2️⃣ Google Auth Tokenları Al
      final googleAuth = await googleUser.authentication.catchError((error) {
        print('Google Auth Hatası: $error');
        throw Exception('Google kimlik doğrulama başarısız: $error');
      });

      if (googleAuth.idToken == null) {
        throw Exception('Google ID token alınamadı. Server Client ID kontrol edin.');
      }

      // 3️⃣ Google Tokenlarını Terminalde Göster
      if (kDebugMode) {
        print('📝 [AUTH] Google kullanıcı bilgileri:');
        print('   - Display Name: ${googleUser.displayName}');
        print('   - Email: ${googleUser.email}');
        print('   - ID: ${googleUser.id}');
        print('   - Photo URL: ${googleUser.photoUrl}');

        print('🔑 [AUTH] Google token bilgileri:');
        print('   - Access Token: ${googleAuth.accessToken}');
        print('   - ID Token: ${googleAuth.idToken}');
      }

      // 4️⃣ Supabase'e Giriş Yap
      final authResponse = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (kDebugMode) {
        print('✅ [AUTH] Supabase auth başarılı');
        print('📝 [AUTH] Supabase kullanıcı bilgileri:');
        print('   - User ID: ${authResponse.user?.id}');
        print('   - Email: ${authResponse.user?.email}');
      }

      // 5️⃣ Profil Güncelleme/Oluşturma
      if (authResponse.user != null) {
        try {
          // Önce profil var mı kontrol et
          final existingProfile = await _supabase
              .from('profiles')
              .select()
              .eq('user_id', authResponse.user!.id)
              .maybeSingle();

          if (kDebugMode) {
            print('�� [AUTH] Mevcut profil kontrolü: ${existingProfile != null ? 'Bulundu' : 'Bulunamadı'}');
          }

          if (existingProfile == null) {
            // Profil yoksa oluştur
            await _supabase.from('profiles').insert({
              'user_id': authResponse.user!.id,
              'full_name': googleUser.displayName ?? 'Kullanıcı',
              'email': googleUser.email,
              'avatar_url': googleUser.photoUrl,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            }).select();

            if (kDebugMode) {
              print('✅ [AUTH] Yeni profil oluşturuldu');
            }
          } else {
            // Profil varsa güncelle
            await _supabase.from('profiles').update({
              'full_name': googleUser.displayName ?? 'Kullanıcı',
              'avatar_url': googleUser.photoUrl,
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('user_id', authResponse.user!.id);

            if (kDebugMode) {
              print('✅ [AUTH] Mevcut profil güncellendi');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ [AUTH] Profil işlemi hatası:');
            print('   - Hata: $e');
            print('   - Stack trace: ${StackTrace.current}');
          }
        }
      }

      return authResponse;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AUTH] Google giriş hatası:');
        print('   - Hata: $e');
        print('   - Stack trace: ${StackTrace.current}');
      }
      rethrow;
    }
  }

  // Çıkış yapma
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Oturum durumunu kontrol et
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  // E-posta doğrulama durumunu kontrol et
  bool isEmailVerified() {
    final user = _supabase.auth.currentUser;
    final userMetadata = user?.userMetadata;
    return userMetadata?['email_verified'] == true;
  }

  // Şifre sıfırlama e-postası gönder
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.yemekdunyasi://reset-callback/'
    );
  }

  // Email kontrolü
  Future<bool> _checkEmailExists(String email) async {
    try {
      final response = await _supabase.rpc(
        'check_email_exists',
        params: {'email_address': email},
      );
      return response as bool;
    } catch (e) {
      return false;
    }
  }

  // Email Onayı Kontrolü
  Future<bool> confirmEmail() async {
    try {
      await _supabase.auth.refreshSession();
      final user = _supabase.auth.currentUser;
      return user?.emailConfirmedAt != null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AUTH] Email onay kontrolü hatası: $e');
      }
      return false;
    }
  }

  // Email onayı sonrası işlem
  Future<void> handleEmailConfirmation(String accessToken) async {
    try {
      if (kDebugMode) {
        print('📱 [AUTH] Email onayı işlemi başlatıldı');
      }

      final response = await _supabase.auth.getUser(accessToken);
      final user = response.user;
      
      if (user == null) {
        throw Exception('Kullanıcı bilgileri alınamadı');
      }

      final userEmail = user.email;
      if (userEmail == null) {
        throw Exception('Kullanıcı email bilgisi alınamadı');
      }

      if (kDebugMode) {
        print('✅ [AUTH] Email onayı başarılı: $userEmail');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AUTH] Email onayı hatası: $e');
      }
      rethrow;
    }
  }

  // OTP ile giriş/doğrulama
  Future<void> signInWithOtp({
    required String email,
    bool shouldCreateUser = true,
  }) async {
    try {
      debugPrint('\n====== OTP GÖNDERİLİYOR ======');
      debugPrint('📧 Email: $email');

      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.flutterquickstart://login-callback/',
        shouldCreateUser: shouldCreateUser,
      );

      debugPrint('✅ OTP başarıyla gönderildi');
    } catch (e) {
      debugPrint('\n❌ OTP HATASI: $e');
      rethrow;
    } finally {
      debugPrint('====== İŞLEM TAMAMLANDI ======\n');
    }
  }

  // Profil Güncelleme
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    String? avatarUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final updates = {
        'user_id': user.id,
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('profiles').upsert(updates);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AUTH] Profil güncelleme hatası: $e');
      }
      rethrow;
    }
  }

  // Profil Bilgilerini Al
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', user.id)
          .single();
      
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AUTH] Profil getirme hatası: $e');
      }
      return null;
    }
  }

  // Add this getter
  bool get isLoggedIn {
    final user = _supabase.auth.currentUser;
    debugPrint('\n👤 Oturum Kontrolü:');
    debugPrint('- Kullanıcı: ${user?.email}');
    debugPrint('- Oturum: ${_supabase.auth.currentSession?.accessToken}\n');
    return user != null;
  }

  // Email doğrulama durumunu kontrol et
  Future<bool> _checkEmailVerification(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('email_confirmed_at')
          .eq('id', userId)
          .single();
      
      return response['email_confirmed_at'] != null;
    } catch (e) {
      debugPrint('❌ Email doğrulama kontrolü hatası: $e');
      return false;
    }
  }

  // Email doğrulama
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
  }) async {
    try {
      debugPrint('\n====== EMAIL DOĞRULAMA ======');
      debugPrint('📧 Email: $email');
      debugPrint('🔑 Token: $token');

      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );

      if (response.user == null) {
        throw AuthException(
          message: 'Doğrulama başarısız oldu',
          statusCode: '400',
          errorCode: 'verification_failed'
        );
      }

      debugPrint('✅ Email doğrulama başarılı');
      debugPrint('👤 Kullanıcı ID: ${response.user!.id}');

      // Email doğrulama durumunu güncelle
      await _supabase.from('profiles').update({
        'email_confirmed_at': DateTime.now().toIso8601String(),
      }).eq('id', response.user!.id);

      return response;
    } catch (e) {
      debugPrint('\n❌ DOĞRULAMA HATASI: $e');
      rethrow;
    } finally {
      debugPrint('====== İŞLEM TAMAMLANDI ======\n');
    }
  }
} 
