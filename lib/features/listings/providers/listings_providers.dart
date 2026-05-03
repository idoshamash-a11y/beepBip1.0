import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../../core/errors/failure.dart';
import '../../../core/errors/supabase_failure_mapper.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/result/result.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/models/profile_enums.dart';
import '../../profile/models/profile_model.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/supabase_listing_repository.dart';
import '../domain/listing_repository.dart';
import '../models/listing_enums.dart';
import '../models/listing_model.dart';

// ---------------------------------------------------------------------------
// Repository wiring
// ---------------------------------------------------------------------------

/// Singleton [ListingRepository] bound to the live Supabase client. Override
/// at the container boundary in tests with an in-memory fake.
final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return SupabaseListingRepository(Supabase.instance.client);
});

// ---------------------------------------------------------------------------
// Helper providers
// ---------------------------------------------------------------------------

/// SoHo neighborhood id from the cloud database, fetched once and cached for
/// the lifetime of the app session. We hardcode the slug because V1 is
/// SoHo-only — when we expand to more neighborhoods this becomes a per-user
/// "active neighborhood" provider with selection UI.
final sohoNeighborhoodIdProvider = FutureProvider<String>((ref) async {
  final row = await Supabase.instance.client
      .from('neighborhoods')
      .select('id')
      .eq('slug', 'soho-nyc')
      .single();
  return row['id'] as String;
});

/// All profiles owned by the signed-in user. Drives the "do you have a
/// business profile?" check. Refetches when auth state changes.
final currentUserProfilesProvider =
    FutureProvider<List<ProfileModel>>((ref) async {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return const [];

  final result = await ref.read(profileRepositoryProvider).getUserProfiles(
        user.id,
      );
  return result.fold(
    onOk: (rows) => rows,
    onErr: (failure) {
      AppLogger.w(
        'currentUserProfilesProvider failed: ${failure.message}',
        tag: 'listings',
      );
      return const [];
    },
  );
});

/// The signed-in user's business profile, if any. Owners use it to author
/// listings; consumers (personal-only users) get null and the create UI is
/// hidden for them per MVP §3.4 "Businesses only in V1".
final currentBusinessProfileProvider = Provider<ProfileModel?>((ref) {
  final profiles = ref.watch(currentUserProfilesProvider).asData?.value ??
      const <ProfileModel>[];
  for (final p in profiles) {
    if (p.profileType == ProfileType.business) return p;
  }
  return null;
});

/// Convenience: is the current user authoring-capable for listings?
final canAuthorListingsProvider = Provider<bool>((ref) {
  return ref.watch(currentBusinessProfileProvider) != null;
});

// ---------------------------------------------------------------------------
// Read providers
// ---------------------------------------------------------------------------

/// Active listings in the SoHo neighborhood, newest first. Consumers (and
/// owners) see this on the browse screen.
final neighborhoodListingsProvider = FutureProvider<List<Listing>>((ref) async {
  final neighborhoodId = await ref.watch(sohoNeighborhoodIdProvider.future);
  final result = await ref
      .read(listingRepositoryProvider)
      .listForNeighborhood(neighborhoodId: neighborhoodId);
  return result.fold(
    onOk: (rows) => rows,
    onErr: (failure) {
      AppLogger.w(
        'neighborhoodListingsProvider failed: ${failure.message}',
        tag: 'listings',
        error: failure.cause,
        stackTrace: failure.stackTrace,
      );
      throw failure;
    },
  );
});

/// Every listing owned by the signed-in user's business profile, in any
/// status. Empty when the user has no business profile.
final myListingsProvider = FutureProvider<List<Listing>>((ref) async {
  final business = ref.watch(currentBusinessProfileProvider);
  if (business == null) return const [];

  final result =
      await ref.read(listingRepositoryProvider).listForOwner(business.id);
  return result.fold(
    onOk: (rows) => rows,
    onErr: (failure) {
      AppLogger.w(
        'myListingsProvider failed: ${failure.message}',
        tag: 'listings',
      );
      throw failure;
    },
  );
});

/// One listing by id, for the detail screen. Family parameter is the id.
final listingByIdProvider =
    FutureProvider.family<Listing?, String>((ref, id) async {
  final result = await ref.read(listingRepositoryProvider).getById(id);
  return result.fold(
    onOk: (row) => row,
    onErr: (failure) {
      AppLogger.w(
        'listingByIdProvider($id) failed: ${failure.message}',
        tag: 'listings',
      );
      throw failure;
    },
  );
});

// ---------------------------------------------------------------------------
// Form controller (create / edit)
// ---------------------------------------------------------------------------

/// State carried by [ListingFormController] while a save is in flight.
class ListingFormState {
  final bool isSubmitting;
  final String? error;

  /// Set on a successful create (so the screen can navigate to detail).
  final Listing? lastSaved;

  const ListingFormState({
    this.isSubmitting = false,
    this.error,
    this.lastSaved,
  });

  ListingFormState copyWith({
    bool? isSubmitting,
    String? error,
    Listing? lastSaved,
    bool clearError = false,
    bool clearLastSaved = false,
  }) {
    return ListingFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      lastSaved: clearLastSaved ? null : (lastSaved ?? this.lastSaved),
    );
  }
}

/// One controller instance per mounted form screen. We use `.autoDispose`
/// so a fresh state is allocated each time the user opens create/edit, and
/// disposed when they leave.
final listingFormControllerProvider = StateNotifierProvider.autoDispose<
    ListingFormController, ListingFormState>((ref) {
  return ListingFormController(ref);
});

class ListingFormController extends StateNotifier<ListingFormState> {
  ListingFormController(this._ref) : super(const ListingFormState());

  final Ref _ref;

  ListingRepository get _repo => _ref.read(listingRepositoryProvider);

  /// Create a new listing for the signed-in user's business profile. Returns
  /// `true` on success; on failure the user-friendly message is in
  /// [ListingFormState.error].
  Future<bool> createListing({
    required ListingType type,
    required String title,
    String? description,
    required int priceCents,
    int? durationMinutes,
    int? capacity,
    int? stock,
    List<String> hashtags = const [],
    List<String> images = const [],
    ListingStatus status = ListingStatus.active,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final business = _ref.read(currentBusinessProfileProvider);
    if (business == null) {
      state = state.copyWith(
        error: 'You need a business profile to create a listing.',
      );
      return false;
    }

    final neighborhoodIdAsync =
        _ref.read(sohoNeighborhoodIdProvider).asData?.value;
    if (neighborhoodIdAsync == null) {
      state = state.copyWith(
        error: 'Neighborhood data is still loading. Try again in a moment.',
      );
      return false;
    }

    return _run(() async {
      final result = await _repo.create(
        profileId: business.id,
        neighborhoodId: neighborhoodIdAsync,
        type: type,
        title: title,
        description: description,
        priceCents: priceCents,
        durationMinutes: durationMinutes,
        capacity: capacity,
        stock: stock,
        hashtags: hashtags,
        images: images,
        status: status,
        startsAt: startsAt,
        endsAt: endsAt,
      );
      return result;
    });
  }

  /// Update an existing listing. Skips fields whose argument is null.
  Future<bool> updateListing({
    required String id,
    ListingType? type,
    String? title,
    String? description,
    int? priceCents,
    int? durationMinutes,
    int? capacity,
    int? stock,
    List<String>? hashtags,
    List<String>? images,
    ListingStatus? status,
    DateTime? startsAt,
    DateTime? endsAt,
  }) {
    return _run(() async {
      final result = await _repo.update(
        id: id,
        type: type,
        title: title,
        description: description,
        priceCents: priceCents,
        durationMinutes: durationMinutes,
        capacity: capacity,
        stock: stock,
        hashtags: hashtags,
        images: images,
        status: status,
        startsAt: startsAt,
        endsAt: endsAt,
      );
      return result;
    });
  }

  /// Delete a listing the caller owns. Invalidates the read providers so
  /// other screens reflect the new state.
  Future<bool> deleteListing(String id) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    final result = await _repo.delete(id);
    return result.fold(
      onOk: (_) {
        state = const ListingFormState();
        _invalidateLists();
        return true;
      },
      onErr: (failure) {
        AppLogger.w(
          'deleteListing failed: ${failure.message}',
          tag: 'listings',
        );
        state = state.copyWith(
          isSubmitting: false,
          error: _humanize(failure),
        );
        return false;
      },
    );
  }

  void clearError() {
    if (state.error != null) state = state.copyWith(clearError: true);
  }

  // --- internals ------------------------------------------------------------

  Future<bool> _run(Future<Result<Listing>> Function() body) async {
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearLastSaved: true,
    );
    try {
      final result = await body();
      return result.fold(
        onOk: (listing) {
          state = ListingFormState(lastSaved: listing);
          _invalidateLists();
          return true;
        },
        onErr: (failure) {
          AppLogger.w(
            'listing form save failed: ${failure.message}',
            tag: 'listings',
          );
          state = state.copyWith(
            isSubmitting: false,
            error: _humanize(failure),
          );
          return false;
        },
      );
    } catch (e, st) {
      final failure = SupabaseFailureMapper.map(e, st);
      AppLogger.e(
        'listing form save threw',
        tag: 'listings',
        error: e,
        stackTrace: st,
      );
      state = state.copyWith(
        isSubmitting: false,
        error: _humanize(failure),
      );
      return false;
    }
  }

  void _invalidateLists() {
    _ref.invalidate(neighborhoodListingsProvider);
    _ref.invalidate(myListingsProvider);
  }

  String _humanize(Failure f) {
    return switch (f) {
      UnauthenticatedFailure() =>
        'Your session expired. Sign in again to keep editing.',
      UnauthorizedFailure() =>
        "You don't have permission to edit this listing.",
      ConflictFailure() => f.message,
      ValidationFailure() => f.message,
      _ => f.message,
    };
  }
}
