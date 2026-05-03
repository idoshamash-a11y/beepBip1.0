import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/logging/app_logger.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// App entrypoint.
///
/// Startup order is intentional:
///   1. Ensure the Flutter binding (required before any plugin call).
///   2. Load the env file for the selected flavor so [Env] getters are safe.
///   3. Initialize Supabase with the client-safe publishable key.
///   4. Hand off to Riverpod + the app shell.
///
/// If step 2 or 3 fails we render [_StartupFailure] instead of crashing, so
/// the user sees a legible message and we can include a "try again" button
/// once we have one. In prod we will also forward the error to crash reporting.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Env.load();
    AppLogger.init(verbose: Env.debugLogs);
    AppLogger.i('Env loaded for flavor=${Env.flavor}');

    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabasePublishableKey,
      debug: kDebugMode && Env.debugLogs,
    );
    AppLogger.i('Supabase initialized at ${Env.supabaseUrl}');
  } catch (e, st) {
    AppLogger.e('Startup failed', error: e, stackTrace: st);
    runApp(_StartupFailureApp(error: e));
    return;
  }

  runApp(const ProviderScope(child: BeepBipApp()));
}

class BeepBipApp extends ConsumerWidget {
  const BeepBipApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'BEEPBIP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

/// Rendered when startup configuration fails before we can even reach the
/// router. Deliberately uses no app-specific dependencies so it always works.
class _StartupFailureApp extends StatelessWidget {
  const _StartupFailureApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BEEPBIP could not start',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This is a configuration problem, not a user-facing bug. '
                  'Check that the .env file for the current flavor exists and '
                  'has valid SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY values.',
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    error.toString(),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
