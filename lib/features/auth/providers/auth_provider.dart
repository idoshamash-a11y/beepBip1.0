import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Auth state provider - streams the current auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return Stream.value(User(
    id: 'mock-123',
    appMetadata: {},
    userMetadata: {'is_profile_complete': true},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
    updatedAt: DateTime.now().toIso8601String(),
    phone: '',
  ));
});

// Current user profile provider
final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  return UserModel(
    id: 'mock-123',
    serialId: 'BEEP-001',
    email: 'test@example.com',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
});

// Auth controller provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

// Auth state
class AuthState {
  final bool isLoading;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Auth controller
class AuthController extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthController(this._ref) : super(AuthState());

  AuthService get _authService => _ref.read(authServiceProvider);

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.signUpWithEmail(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.signInWithGoogle();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> signInWithFacebook() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.signInWithFacebook();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.signOut();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.resetPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}
