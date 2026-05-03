import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, User;

import '../../../core/errors/supabase_failure_mapper.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/result/result.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../models/user_model.dart';

// ---------------------------------------------------------------------------
// Onboarding state
// ---------------------------------------------------------------------------

/// Coarse-grained auth + onboarding status that the router cares about.
///
/// We keep this deliberately narrow (three cases) so the redirect logic is
/// trivial to read. Finer-grained profile state lives in feature-specific
/// providers.
enum OnboardingState {
  /// No signed-in Supabase user.
  signedOut,

  /// Signed in, but no completed profile yet. Send user to /profile-type.
  needsProfile,

  /// Signed in AND at least one completed profile exists.
  ready,
}

// ---------------------------------------------------------------------------
// Repository wiring
// ---------------------------------------------------------------------------

/// Singleton [AuthRepository]. Concrete impl is constructed here so that
/// tests can `overrideWithValue(FakeAuthRepository())` at the container
/// boundary without touching any consumer.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(Supabase.instance.client);
});

// ---------------------------------------------------------------------------
// Reactive auth state
// ---------------------------------------------------------------------------

/// Streams the current Supabase user, reacting to sign-in / sign-out / token
/// refresh / social login redirects. Emits `null` when signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authChanges;
});

/// Fetches the [UserModel] row for the signed-in user from `public.users`.
/// Re-runs whenever [authStateProvider] emits a new user id.
final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return null;

  final repo = ref.read(authRepositoryProvider);
  final result = await repo.getUserProfile(user.id);
  return result.fold(
    onOk: (model) {
      if (model == null) {
        AppLogger.w(
          'No public.users row for auth user ${user.id}. The '
          'handle_new_auth_user trigger should have created one.',
          tag: 'auth',
        );
      }
      return model;
    },
    onErr: (failure) {
      AppLogger.e(
        'currentUserProfileProvider failed: ${failure.message}',
        tag: 'auth',
        error: failure.cause,
        stackTrace: failure.stackTrace,
      );
      return null;
    },
  );
});

/// Reactive [OnboardingState]. The router uses this to decide whether to send
/// the user to login / onboarding / home.
///
/// We intentionally treat "loading" as [OnboardingState.signedOut] at the
/// router level — this means the initial redirect during app launch will send
/// users to the splash screen (which they'd see anyway). When the real state
/// arrives, the router re-evaluates and routes accordingly.
final onboardingStateProvider = FutureProvider<OnboardingState>((ref) async {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return OnboardingState.signedOut;

  final result =
      await ref.read(profileRepositoryProvider).hasCompletedAnyProfile(user.id);
  return result.fold(
    onOk: (anyComplete) =>
        anyComplete ? OnboardingState.ready : OnboardingState.needsProfile,
    onErr: (failure) {
      AppLogger.e(
        'onboardingStateProvider failed: ${failure.message}',
        tag: 'auth',
        error: failure.cause,
        stackTrace: failure.stackTrace,
      );
      // Fail safe to needs-profile so the user isn't locked out of the app
      // entirely — they'll just see onboarding again.
      return OnboardingState.needsProfile;
    },
  );
});

// ---------------------------------------------------------------------------
// Auth controller
// ---------------------------------------------------------------------------

/// Exposes imperative sign-in / sign-up / sign-out actions. UI screens call
/// these methods and render [AuthState] (loading + last error) while they run.
///
/// The controller still returns `Future<bool>` (success / failure) to keep
/// the existing screen call sites simple, but internally each operation goes
/// through the typed [Result] surface from [AuthRepository] so the failure
/// path is structured.
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

class AuthState {
  final bool isLoading;
  final String? error;

  const AuthState({this.isLoading = false, this.error});

  AuthState copyWith({bool? isLoading, String? error}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthController(this._ref) : super(const AuthState());

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  Future<bool> _runResult<T>(Future<Result<T>> Function() body) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await body();
      return result.fold<bool>(
        onOk: (_) {
          state = state.copyWith(isLoading: false);
          return true;
        },
        onErr: (failure) {
          AppLogger.w(
            'auth op failed: ${failure.message}',
            tag: 'auth',
            error: failure.cause,
            stackTrace: failure.stackTrace,
          );
          state = state.copyWith(isLoading: false, error: failure.message);
          return false;
        },
      );
    } catch (e, st) {
      // Defense in depth: a bug in the repo (not a Failure path) shouldn't
      // crash the controller. Map and surface like any other failure.
      final failure = SupabaseFailureMapper.map(e, st);
      AppLogger.e('auth op threw', tag: 'auth', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: failure.message);
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) =>
      _runResult(() => _repo.signUpWithEmail(email: email, password: password));

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _runResult(() => _repo.signInWithEmail(email: email, password: password));

  Future<bool> signInWithGoogle() => _runResult(_repo.signInWithGoogle);

  Future<bool> signInWithFacebook() => _runResult(_repo.signInWithFacebook);

  Future<bool> signInWithApple() => _runResult(_repo.signInWithApple);

  Future<bool> resetPassword(String email) =>
      _runResult(() => _repo.resetPassword(email));

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repo.signOut();
    if (result case Err<void>(failure: final f)) {
      AppLogger.w('signOut failed: ${f.message}', tag: 'auth');
      state = state.copyWith(error: f.message);
    }
    state = state.copyWith(isLoading: false);
  }

  /// Manually clear the last error from state. Useful when the UI dismisses
  /// an error banner.
  void clearError() {
    if (state.error != null) state = state.copyWith();
  }
}
