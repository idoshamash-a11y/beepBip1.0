import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../../core/errors/failure.dart';
import '../../../core/errors/supabase_failure_mapper.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/result/result.dart';
import '../../auth/providers/auth_provider.dart' show onboardingStateProvider;
import '../data/supabase_profile_repository.dart';
import '../domain/profile_repository.dart';
import '../models/profile_enums.dart';

// ---------------------------------------------------------------------------
// Repository wiring
// ---------------------------------------------------------------------------

/// Singleton [ProfileRepository] bound to the live Supabase client. Tests can
/// override at the container boundary with an in-memory fake.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(Supabase.instance.client);
});

// ---------------------------------------------------------------------------
// Profile setup controller
// ---------------------------------------------------------------------------

/// Status flag for the multi-step onboarding flow. The screens render
/// loading + last error from this; on success they navigate themselves.
class ProfileSetupState {
  final bool isLoading;
  final String? error;

  const ProfileSetupState({this.isLoading = false, this.error});

  ProfileSetupState copyWith({bool? isLoading, String? error}) {
    return ProfileSetupState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Composes the multi-step "create profile + create personal/business
/// profile + mark complete" flow that the setup screens kick off.
///
/// Each step goes through the typed [ProfileRepository] surface, so the
/// controller can stop early on the first failure and surface a single
/// user-readable message. Internal partial state (e.g. the `profiles` row
/// that was created before `personal_profiles` failed) is intentionally left
/// in the database — a follow-up cleanup task can sweep orphans, and on
/// retry the user can either delete and recreate or we can detect the
/// orphan and resume.
final profileSetupControllerProvider =
    StateNotifierProvider<ProfileSetupController, ProfileSetupState>((ref) {
  return ProfileSetupController(ref);
});

class ProfileSetupController extends StateNotifier<ProfileSetupState> {
  final Ref _ref;

  ProfileSetupController(this._ref) : super(const ProfileSetupState());

  ProfileRepository get _repo => _ref.read(profileRepositoryProvider);

  /// Create a personal profile and mark it complete in a single call. Returns
  /// `true` on success; on failure, [state.error] holds the message to show.
  Future<bool> setupPersonalProfile({
    required String userId,
    required String name,
    String? phone,
    String? bio,
    List<String>? interests,
    String? photoUrl,
    DateTime? dateOfBirth,
    String? gender,
    VisibilityStatus visibilityStatus = VisibilityStatus.open,
    LocationSharing locationSharing = LocationSharing.dontShare,
  }) {
    return _composeSetup(() async {
      final create = await _repo.createProfile(
        userId: userId,
        profileType: ProfileType.personal,
      );
      if (create case Err<dynamic>(failure: final f)) return Err(f);

      final profile = (create as Ok).value;

      final personal = await _repo.createPersonalProfile(
        profileId: profile.id,
        name: name,
        phone: _emptyToNull(phone),
        bio: _emptyToNull(bio),
        interests: interests,
        photoUrl: photoUrl,
        dateOfBirth: dateOfBirth,
        gender: gender,
      );
      if (personal case Err<dynamic>(failure: final f)) return Err(f);

      final updated = await _repo.updateProfile(
        profileId: profile.id,
        visibilityStatus: visibilityStatus,
        locationSharing: locationSharing,
        isProfileComplete: true,
      );
      if (updated case Err<dynamic>(failure: final f)) return Err(f);

      return const Ok(null);
    });
  }

  /// Create a business profile (Business Pro tier) and mark it complete.
  Future<bool> setupBusinessProfile({
    required String userId,
    required String businessName,
    String? logoUrl,
    String? coverUrl,
    String? description,
    String? category,
    List<String>? services,
    List<String>? hashtags,
    Map<String, String>? socialHandles,
    String? website,
    String? phone,
    String? email,
    VisibilityStatus visibilityStatus = VisibilityStatus.open,
    LocationSharing locationSharing = LocationSharing.visibleWithLocation,
  }) {
    return _composeSetup(() async {
      final create = await _repo.createProfile(
        userId: userId,
        profileType: ProfileType.business,
        subscriptionTier: SubscriptionTier.businessPro,
      );
      if (create case Err<dynamic>(failure: final f)) return Err(f);

      final profile = (create as Ok).value;

      final business = await _repo.createBusinessProfile(
        profileId: profile.id,
        businessName: businessName,
        description: _emptyToNull(description),
        category: _emptyToNull(category),
        services: services,
        hashtags: hashtags,
        socialHandles: socialHandles,
        website: _emptyToNull(website),
        phone: _emptyToNull(phone),
        email: _emptyToNull(email),
        logoUrl: logoUrl,
        coverUrl: coverUrl,
      );
      if (business case Err<dynamic>(failure: final f)) return Err(f);

      final updated = await _repo.updateProfile(
        profileId: profile.id,
        visibilityStatus: visibilityStatus,
        locationSharing: locationSharing,
        isProfileComplete: true,
      );
      if (updated case Err<dynamic>(failure: final f)) return Err(f);

      return const Ok(null);
    });
  }

  /// Manually clear the last error, e.g. when the user dismisses an error.
  void clearError() {
    if (state.error != null) state = state.copyWith();
  }

  // --- internal helpers -----------------------------------------------------

  Future<bool> _composeSetup(
    Future<Result<void>> Function() body,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await body();
      return result.fold<bool>(
        onOk: (_) {
          state = state.copyWith(isLoading: false);
          // CRITICAL: tell the router-watched onboarding provider to recompute.
          // Without this, the router still sees the previous (stale) state of
          // `needsProfile` when the screen calls `context.go('/home')`, and
          // bounces the user right back to /profile-type.
          _ref.invalidate(onboardingStateProvider);
          return true;
        },
        onErr: (failure) {
          AppLogger.w(
            'profile setup failed: ${failure.message}',
            tag: 'profile',
            error: failure.cause,
            stackTrace: failure.stackTrace,
          );
          state = state.copyWith(
            isLoading: false,
            error: _humanize(failure),
          );
          return false;
        },
      );
    } catch (e, st) {
      final failure = SupabaseFailureMapper.map(e, st);
      AppLogger.e('profile setup threw',
          tag: 'profile', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: _humanize(failure));
      return false;
    }
  }

  /// Tweak a few failure messages to be friendlier in the setup context.
  /// The generic [Failure.message] is fine elsewhere; here we know the user
  /// is mid-onboarding and can give a more directive nudge.
  String _humanize(Failure f) {
    return switch (f) {
      UnauthenticatedFailure() =>
        'Your session expired. Please sign in again to continue setting up.',
      ConflictFailure() =>
        'It looks like a profile already exists for this account. Try refreshing.',
      ValidationFailure() => f.message,
      _ => f.message,
    };
  }

  String? _emptyToNull(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
