import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConstants {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Validation
  static bool get isValid => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
} 