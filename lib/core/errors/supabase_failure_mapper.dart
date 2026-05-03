import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'failure.dart';

/// Converts exceptions thrown by the Supabase SDK into our [Failure] hierarchy.
///
/// All repository methods that touch Supabase should funnel errors through
/// this mapper so the rest of the app sees a predictable, typed error surface.
///
/// Mapping rules:
///   * [AuthException] / [AuthApiException] — inspect the message / status
///     and branch into the most specific auth [Failure] we can.
///   * [PostgrestException] — map common Postgres error codes to
///     [NotFoundFailure] / [ConflictFailure] / [ValidationFailure] /
///     [UnauthorizedFailure], otherwise [ServerFailure].
///   * [StorageException] — currently just [ServerFailure] (revisit once we
///     touch Storage heavily).
///   * [SocketException] / any net-layer error — [NoConnectionFailure].
///   * Anything else — [UnknownFailure] (logged upstream).
class SupabaseFailureMapper {
  SupabaseFailureMapper._();

  static Failure map(Object error, [StackTrace? stackTrace]) {
    final st = stackTrace ?? StackTrace.current;

    if (error is Failure) return error;

    if (error is SocketException) {
      return NoConnectionFailure(cause: error, stackTrace: st);
    }

    if (error is AuthApiException) {
      return _mapAuthApi(error, st);
    }

    if (error is AuthException) {
      return _mapAuthException(error, st);
    }

    if (error is PostgrestException) {
      return _mapPostgrest(error, st);
    }

    if (error is StorageException) {
      return ServerFailure(
        error.message,
        cause: error,
        stackTrace: st,
      );
    }

    return UnknownFailure(error.toString(), cause: error, stackTrace: st);
  }

  static Failure _mapAuthApi(AuthApiException e, StackTrace st) {
    final status = int.tryParse(e.statusCode ?? '');
    final msg = e.message.toLowerCase();

    if (status == 400 && (msg.contains('credentials') || msg.contains('password'))) {
      return InvalidCredentialsFailure(message: e.message, cause: e, stackTrace: st);
    }
    if (status == 401) {
      return UnauthenticatedFailure(cause: e, stackTrace: st);
    }
    if (status == 403) {
      return UnauthorizedFailure(cause: e, stackTrace: st);
    }
    if (status == 404) {
      return NotFoundFailure(message: e.message, cause: e, stackTrace: st);
    }
    if (status == 422) {
      return ValidationFailure(e.message, cause: e, stackTrace: st);
    }
    if (status == 429) {
      return RateLimitedFailure(cause: e, stackTrace: st);
    }

    return ServerFailure(e.message, statusCode: status, cause: e, stackTrace: st);
  }

  static Failure _mapAuthException(AuthException e, StackTrace st) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid password') ||
        msg.contains('invalid otp')) {
      return InvalidCredentialsFailure(message: e.message, cause: e, stackTrace: st);
    }
    if (msg.contains('email not confirmed')) {
      return AccountNotUsableFailure(
        'Please confirm your email before signing in.',
        cause: e,
        stackTrace: st,
      );
    }
    if (msg.contains('user not found')) {
      return NotFoundFailure(message: e.message, cause: e, stackTrace: st);
    }
    return ServerFailure(e.message, cause: e, stackTrace: st);
  }

  static Failure _mapPostgrest(PostgrestException e, StackTrace st) {
    // See https://www.postgresql.org/docs/current/errcodes-appendix.html
    switch (e.code) {
      case '23505': // unique_violation
        return ConflictFailure(
          e.message,
          cause: e,
          stackTrace: st,
        );
      case '23503': // foreign_key_violation
      case '23514': // check_violation
      case '23502': // not_null_violation
        return ValidationFailure(e.message, cause: e, stackTrace: st);
      case '42501': // insufficient_privilege — RLS denial
        return UnauthorizedFailure(cause: e, stackTrace: st);
      case 'PGRST116': // PostgREST: no rows returned for single()
        return NotFoundFailure(message: e.message, cause: e, stackTrace: st);
    }
    return ServerFailure(e.message, cause: e, stackTrace: st);
  }
}
