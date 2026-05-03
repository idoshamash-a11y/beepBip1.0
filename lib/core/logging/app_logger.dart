import 'package:flutter/foundation.dart';

/// Minimal app-wide logging facade.
///
/// Rationale for a wrapper instead of calling `debugPrint` everywhere:
///   * Single switch to silence or redirect logs in prod.
///   * Easy to later route errors to Crashlytics / Sentry without touching
///     every call site.
///   * Keeps import graph clean — feature code depends on [AppLogger], not
///     on the logging vendor of the week.
///
/// Levels map loosely to the classic debug/info/warn/error. Anything below
/// [_verbose] is skipped when [init] is called with `verbose: false`.
class AppLogger {
  AppLogger._();

  static bool _verbose = true;

  static void init({required bool verbose}) {
    _verbose = verbose;
  }

  /// Debug-level message. Suppressed in release builds and when verbose=false.
  static void d(String message, {String? tag}) {
    if (!_verbose || !kDebugMode) return;
    _emit('D', tag, message);
  }

  /// Informational message; always shown when verbose=true.
  static void i(String message, {String? tag}) {
    if (!_verbose) return;
    _emit('I', tag, message);
  }

  /// Warning. Emitted regardless of verbose so operational issues surface.
  static void w(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _emit('W', tag, message, error: error, stackTrace: stackTrace);
  }

  /// Error. Emitted regardless of verbose; in prod hook this up to crash
  /// reporting (Crashlytics / Sentry) inside [_emit] below.
  static void e(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _emit('E', tag, message, error: error, stackTrace: stackTrace);
  }

  static void _emit(
    String level,
    String? tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final prefix = tag == null ? '[$level]' : '[$level][$tag]';
    debugPrint('$prefix $message');
    if (error != null) debugPrint('$prefix  error: $error');
    if (stackTrace != null) debugPrint('$prefix  stack:\n$stackTrace');
  }
}
