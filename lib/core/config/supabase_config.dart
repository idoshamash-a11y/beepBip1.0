import 'env.dart';

/// DEPRECATED thin shim around [Env].
///
/// All new code should import `env.dart` and use [Env] directly. This file
/// remains only so existing imports of `supabase_config.dart` keep compiling
/// during the migration. Remove once no callers reference [SupabaseConfig].
@Deprecated('Use Env from lib/core/config/env.dart instead.')
class SupabaseConfig {
  SupabaseConfig._();

  static String get supabaseUrl     => Env.supabaseUrl;
  static String get supabaseAnonKey => Env.supabasePublishableKey;

  static String get googleClientId  => Env.googleIosClientId;
  static String get facebookAppId   => Env.facebookAppId;
}
