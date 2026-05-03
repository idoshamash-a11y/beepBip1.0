import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../../../core/result/result.dart';
import '../models/user_model.dart';

/// Domain-facing contract for everything authentication-related.
///
/// The application layer (controllers / providers) depends on this interface,
/// not on the concrete Supabase implementation. That makes it possible to:
///   * swap the backend later without rewriting controllers,
///   * write fast unit tests with an in-memory fake,
///   * keep one place where every auth failure is mapped to a [Failure].
///
/// Note: this interface still references Supabase's [User] type for the
/// auth-state stream. Fully decoupling that requires introducing our own
/// `AuthIdentity` value object — tracked as a V1.5 cleanup. The win we keep
/// today is that the *failure surface* is fully typed via [Result].
abstract class AuthRepository {
  /// Currently signed-in Supabase user, or `null` if signed out.
  User? get currentUser;

  /// Reactive stream of the signed-in user. Emits the current value on
  /// subscribe, then a new value on every sign-in / sign-out / token refresh.
  Stream<User?> get authChanges;

  // --- Email + password ------------------------------------------------------

  Future<Result<User?>> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<Result<User?>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Result<void>> resetPassword(String email);

  // --- Social login ----------------------------------------------------------

  Future<Result<User?>> signInWithGoogle();

  Future<Result<User?>> signInWithFacebook();

  /// Sign in with Apple. Currently only meaningful on iOS / macOS / web with
  /// a configured Apple Service ID. On Android this returns a
  /// [DomainFailure] until we wire the web-flow fallback.
  Future<Result<User?>> signInWithApple();

  // --- Session lifecycle -----------------------------------------------------

  Future<Result<void>> signOut();

  // --- App-side user record --------------------------------------------------

  /// Fetches the row from `public.users` mirrored from `auth.users`. Returns
  /// `Ok(null)` if the row hasn't been created yet (the auth-bridge trigger
  /// is async on first signup — callers should treat `null` as transient).
  Future<Result<UserModel?>> getUserProfile(String userId);

  /// Best-effort heartbeat. Failures are swallowed to a [Result] but never
  /// surfaced to the UI — call sites typically ignore the return value.
  Future<Result<void>> updateLastSeen();
}
