import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseInit {
  static Future<void> initialize() async {
    try {
      // Önce .env dosyasını yükle
      await dotenv.load();
      
      if (kDebugMode) {
        print('📝 [SUPABASE] .env dosyası yüklendi');
        print('🔑 [SUPABASE] URL ve Key kontrol ediliyor...');
      }

      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl == null || supabaseAnonKey == null) {
        throw Exception('SUPABASE_URL veya SUPABASE_ANON_KEY bulunamadı!');
      }

      // Supabase'i başlat
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
      );
      
      if (kDebugMode) {
        print('✅ [SUPABASE] Bağlantı başarılı');
        
        // Mevcut kullanıcı bilgisini kontrol et
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          print('👤 [SUPABASE] Mevcut kullanıcı: ${currentUser.email}');
        } else {
          print('ℹ️ [SUPABASE] Oturum açık değil');
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ [SUPABASE] Başlatma hatası:');
        print('📍 Hata: $e');
        print('📍 Stack: $stack');
      }
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
} 