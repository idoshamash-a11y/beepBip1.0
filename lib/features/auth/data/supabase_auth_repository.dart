import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failure.dart';
import '../../../core/errors/supabase_failure_mapper.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/result/result.dart';
import '../domain/auth_repository.dart';
import '../models/user_model.dart';

/// Supabase-backed implementation of [AuthRepository].
///
/// Every public method funnels its body through [Result.guardAsync] +
/// [SupabaseFailureMapper] so callers get a typed [Failure] on the error
/// path instead of a raw SDK exception. Cancellation by the user (e.g. they
/// dismiss the Google sheet) is treated as a [DomainFailure] with a
/// user-readable message — not as an error worth crash-reporting.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._supabase);

  final SupabaseClient _supabase;

  @override
  User? get currentUser => _supabase.auth.currentUser;

  @override
  Stream<User?> get authChanges async* {
    yield _supabase.auth.currentUser;
    yield* _supabase.auth.onAuthStateChange.map((event) {
      AppLogger.d('auth event: ${event.event}', tag: 'auth');
      return event.session?.user;
    });
  }

  // --- Email + password ------------------------------------------------------

  @override
  Future<Result<User?>> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return Result.guardAsync<User?>(
      () async {
        final res = await _supabase.auth.signUp(email: email, password: password);
        return res.user;
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  @override
  Future<Result<User?>> signInWithEmail({
    required String email,
    required String password,
  }) {
    return Result.guardAsync<User?>(
      () async {
        final res = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        return res.user;
      },
      onError: SupabaseFailureMapper.map,
    );
  }

  @override
  Future<Result<void>> resetPassword(String email) {
    return Result.guardAsync<void>(
      () => _supabase.auth.resetPasswordForEmail(email),
      onError: SupabaseFailureMapper.map,
    );
  }

  // --- Social login ----------------------------------------------------------

  @override
  Future<Result<User?>> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(scopes: const ['email']);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return const Err(DomainFailure('Google sign-in was cancelled.'));
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;
      if (accessToken == null || idToken == null) {
        return const Err(DomainFailure(
          'Google did not return a usable session token. Try again.',
        ));
      }

      final res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      return Ok(res.user);
    } catch (e, st) {
      AppLogger.w('signInWithGoogle failed', tag: 'auth', error: e, stackTrace: st);
      return Err(SupabaseFailureMapper.map(e, st));
    }
  }

  @override
  Future<Result<User?>> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login();
      switch (result.status) {
        case LoginStatus.cancelled:
          return const Err(DomainFailure('Facebook sign-in was cancelled.'));
        case LoginStatus.failed:
        case LoginStatus.operationInProgress:
          return Err(DomainFailure(
            'Facebook sign-in failed: ${result.message ?? 'unknown error'}.',
          ));
        case LoginStatus.success:
          break;
      }

      final accessToken = result.accessToken;
      if (accessToken == null) {
        return const Err(DomainFailure(
          'Facebook did not return an access token.',
        ));
      }

      final res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.facebook,
        idToken: accessToken.token,
      );
      return Ok(res.user);
    } catch (e, st) {
      AppLogger.w('signInWithFacebook failed', tag: 'auth', error: e, stackTrace: st);
      return Err(SupabaseFailureMapper.map(e, st));
    }
  }

  @override
  Future<Result<User?>> signInWithApple() async {
    if (!_appleNativeAvailable) {
      return const Err(DomainFailure(
        'Sign in with Apple isn\'t supported on this device yet.',
      ));
    }
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        return const Err(DomainFailure(
          'Apple did not return an identity token. Try again.',
        ));
      }
      final res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );
      return Ok(res.user);
    } on SignInWithAppleAuthorizationException catch (e, st) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return const Err(DomainFailure('Apple sign-in was cancelled.'));
      }
      AppLogger.w('signInWithApple authorization error',
          tag: 'auth', error: e, stackTrace: st);
      return Err(DomainFailure('Apple sign-in failed: ${e.message}'));
    } catch (e, st) {
      AppLogger.w('signInWithApple failed', tag: 'auth', error: e, stackTrace: st);
      return Err(SupabaseFailureMapper.map(e, st));
    }
  }

  /// Native Apple Sign In is supported on iOS, macOS and the web. Android
  /// requires the web-fallback flow which we haven't wired up yet — see
  /// FOLLOWUPS §1.4.
  bool get _appleNativeAvailable {
    if (kIsWeb) return true;
    try {
      return Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  // --- Session lifecycle -----------------------------------------------------

  @override
  Future<Result<void>> signOut() {
    return Result.guardAsync<void>(
      () => _supabase.auth.signOut(),
      onError: SupabaseFailureMapper.map,
    );
  }

  // --- App-side user record --------------------------------------------------

  @override
  Future<Result<UserModel?>> getUserProfile(String userId) async {
    try {
      final row = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return const Ok(null);
      return Ok(UserModel.fromJson(row));
    } catch (e, st) {
      return Err(SupabaseFailureMapper.map(e, st));
    }
  }

  @override
  Future<Result<void>> updateLastSeen() async {
    final userId = currentUser?.id;
    if (userId == null) {
      return const Err(UnauthenticatedFailure());
    }
    return Result.guardAsync<void>(
      () => _supabase.from('users').update({
            'last_seen_at': DateTime.now().toIso8601String(),
          }).eq('id', userId),
      onError: SupabaseFailureMapper.map,
    );
  }
}
