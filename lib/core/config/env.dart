import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to environment configuration.
///
/// Values come from a flavored dotenv file (`.env.dev`, `.env.staging`,
/// `.env.prod`) selected by `--dart-define=FLAVOR=<name>` at build time and
/// loaded via [Env.load] during startup, BEFORE `runApp`.
///
/// Design rules:
///   * Nothing here is `const`. dotenv is runtime-loaded, so the getters must
///     be accessed after [load] completes.
///   * Only ship client-safe values through this class. The `service_role`
///     key, Stripe secret, webhook signing secret, etc. MUST NOT be referenced
///     here — they belong on the server.
///   * Callers treat Env as a read-only source of truth. Do NOT mutate dotenv
///     from elsewhere in the app.
class Env {
  Env._();

  /// Build-time selected flavor. Passed via `--dart-define=FLAVOR=...`.
  /// Defaults to `dev` so `flutter run` (no flags) does the right thing.
  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  static bool _loaded = false;

  /// Load the appropriate `.env.<flavor>` file. Safe to call multiple times;
  /// second+ calls are no-ops.
  ///
  /// Throws [EnvNotLoadedException] if the target file is missing or blank
  /// for keys we treat as required. Callers in `main.dart` should catch and
  /// render a fatal-error screen rather than crash silently.
  static Future<void> load() async {
    if (_loaded) return;

    const fileName = '.env.$flavor';
    try {
      await dotenv.load(fileName: fileName);
    } catch (e) {
      throw EnvNotLoadedException(
        'Could not load $fileName. Ensure the file exists at the repo root '
        'and is listed under flutter > assets in pubspec.yaml. Underlying: $e',
      );
    }

    _assertRequiredKeysPresent();
    _loaded = true;
  }

  static void _assertRequiredKeysPresent() {
    const required = <String>[
      'SUPABASE_URL',
      'SUPABASE_PUBLISHABLE_KEY',
    ];
    final missing = required
        .where((k) => (dotenv.env[k] ?? '').trim().isEmpty)
        .toList();
    if (missing.isNotEmpty) {
      throw EnvNotLoadedException(
        'Missing required env keys for flavor "$flavor": ${missing.join(', ')}. '
        'Check .env.$flavor against .env.example.',
      );
    }
  }

  static String _require(String key) {
    final value = (dotenv.env[key] ?? '').trim();
    if (value.isEmpty) {
      throw StateError(
        'Env.$key is empty. Env.load() must complete before reading values, '
        'and .env.$flavor must define $key.',
      );
    }
    return value;
  }

  static String _optional(String key, {String fallback = ''}) {
    final value = (dotenv.env[key] ?? '').trim();
    return value.isEmpty ? fallback : value;
  }

  // ---- Core -----------------------------------------------------------------
  static String get supabaseUrl            => _require('SUPABASE_URL');
  static String get supabasePublishableKey => _require('SUPABASE_PUBLISHABLE_KEY');

  // ---- Maps -----------------------------------------------------------------
  static String get mapTilerApiKey         => _optional('MAPTILER_API_KEY');

  // ---- Social login ---------------------------------------------------------
  static String get appleServiceId         => _optional('APPLE_SERVICE_ID');
  static String get googleIosClientId      => _optional('GOOGLE_IOS_CLIENT_ID');
  static String get googleAndroidClientId  => _optional('GOOGLE_ANDROID_CLIENT_ID');
  static String get facebookAppId          => _optional('FACEBOOK_APP_ID');

  // ---- Payments -------------------------------------------------------------
  static String get stripePublishableKey   => _optional('STRIPE_PUBLISHABLE_KEY');

  // ---- Observability --------------------------------------------------------
  static String get posthogApiKey          => _optional('POSTHOG_API_KEY');
  static String get posthogHost            => _optional('POSTHOG_HOST');
  static String get crashReportingDsn      => _optional('CRASH_REPORTING_DSN');

  // ---- App behavior ---------------------------------------------------------
  static String get defaultNeighborhoodSlug =>
      _optional('DEFAULT_NEIGHBORHOOD_SLUG', fallback: 'soho-nyc');

  static bool get debugLogs =>
      _optional('DEBUG_LOGS', fallback: 'false').toLowerCase() == 'true';

  // ---- Derived --------------------------------------------------------------
  static bool get isDev     => flavor == 'dev';
  static bool get isStaging => flavor == 'staging';
  static bool get isProd    => flavor == 'prod';
}

/// Thrown when required env configuration is missing at startup.
class EnvNotLoadedException implements Exception {
  final String message;
  EnvNotLoadedException(this.message);

  @override
  String toString() => 'EnvNotLoadedException: $message';
}
