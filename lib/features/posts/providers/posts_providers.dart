import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../../core/errors/failure.dart';
import '../../../core/errors/supabase_failure_mapper.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/result/result.dart';
import '../../listings/providers/listings_providers.dart' show sohoNeighborhoodIdProvider;
import '../../profile/models/profile_model.dart';
import '../data/supabase_post_repository.dart';
import '../domain/post_repository.dart';
import '../models/post_model.dart';

// ---------------------------------------------------------------------------
// Repository wiring
// ---------------------------------------------------------------------------

/// Singleton [PostRepository] bound to the live Supabase client. Override
/// at the container boundary in tests with an in-memory fake.
final postRepositoryProvider = Provider<PostRepository>((ref) {
  return SupabasePostRepository(Supabase.instance.client);
});

// ---------------------------------------------------------------------------
// Banned-hashtags client cache
// ---------------------------------------------------------------------------

/// Snapshot of the `banned_hashtags` table loaded once at app start. The
/// post / listing forms consult this for instant UX feedback before
/// submitting; the DB enforces the rule again via trigger as a backstop.
///
/// Severity buckets:
///   * `block`  — submission is rejected outright.
///   * `review` — submission is allowed, but the post enters the
///                moderation queue (FOLLOWUPS §1.7.b). For now there is
///                no queue, so we just allow them through.
///   * `hide`   — server-side filter; client doesn't need to know.
final bannedHashtagsProvider =
    FutureProvider<BannedHashtagSnapshot>((ref) async {
  try {
    final rows = await Supabase.instance.client
        .from('banned_hashtags')
        .select('tag, severity');
    final blocked = <String>{};
    final review = <String>{};
    for (final r in (rows as List).cast<Map<String, dynamic>>()) {
      final tag = (r['tag'] as String).toLowerCase();
      final severity = r['severity'] as String? ?? 'block';
      if (severity == 'block') blocked.add(tag);
      if (severity == 'review') review.add(tag);
    }
    return BannedHashtagSnapshot(blocked: blocked, review: review);
  } catch (e, st) {
    AppLogger.w(
      'bannedHashtagsProvider failed; falling back to empty set',
      tag: 'posts',
      error: e,
      stackTrace: st,
    );
    return const BannedHashtagSnapshot(blocked: {}, review: {});
  }
});

class BannedHashtagSnapshot {
  final Set<String> blocked;
  final Set<String> review;

  const BannedHashtagSnapshot({required this.blocked, required this.review});

  /// Returns the offending tag if any of [tags] is on the block list, else
  /// null. Tag matching is case-insensitive and ignores leading `#`.
  String? firstBlocked(Iterable<String> tags) {
    for (final raw in tags) {
      final t = raw.toLowerCase().replaceFirst(RegExp(r'^#'), '');
      if (blocked.contains(t)) return t;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Read providers
// ---------------------------------------------------------------------------

/// Visible posts in the SoHo neighborhood, newest first. The Discover Feed
/// consumes this. Refetches when [sohoNeighborhoodIdProvider] settles.
final neighborhoodPostsProvider = FutureProvider<List<Post>>((ref) async {
  final neighborhoodId = await ref.watch(sohoNeighborhoodIdProvider.future);
  final result = await ref
      .read(postRepositoryProvider)
      .listForNeighborhood(neighborhoodId: neighborhoodId);
  return result.fold(
    onOk: (rows) => rows,
    onErr: (failure) {
      AppLogger.w(
        'neighborhoodPostsProvider failed: ${failure.message}',
        tag: 'posts',
      );
      throw failure;
    },
  );
});

/// Posts authored by [profileId] (any state). Family-keyed so we can
/// independently fetch each profile's authored history.
final postsByAuthorProvider =
    FutureProvider.family<List<Post>, String>((ref, profileId) async {
  final result =
      await ref.read(postRepositoryProvider).listForAuthor(profileId);
  return result.fold(
    onOk: (rows) => rows,
    onErr: (failure) {
      AppLogger.w(
        'postsByAuthorProvider($profileId) failed: ${failure.message}',
        tag: 'posts',
      );
      throw failure;
    },
  );
});

/// One post by id, for detail views.
final postByIdProvider =
    FutureProvider.family<Post?, String>((ref, id) async {
  final result = await ref.read(postRepositoryProvider).getById(id);
  return result.fold(
    onOk: (row) => row,
    onErr: (failure) {
      AppLogger.w(
        'postByIdProvider($id) failed: ${failure.message}',
        tag: 'posts',
      );
      throw failure;
    },
  );
});

// ---------------------------------------------------------------------------
// Form controller
// ---------------------------------------------------------------------------

class PostFormState {
  final bool isSubmitting;
  final String? error;

  /// Set on successful create so the screen can navigate / dismiss.
  final Post? lastSaved;

  const PostFormState({
    this.isSubmitting = false,
    this.error,
    this.lastSaved,
  });

  PostFormState copyWith({
    bool? isSubmitting,
    String? error,
    Post? lastSaved,
    bool clearError = false,
    bool clearLastSaved = false,
  }) {
    return PostFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      lastSaved: clearLastSaved ? null : (lastSaved ?? this.lastSaved),
    );
  }
}

/// One controller per mounted form (`autoDispose`).
final postFormControllerProvider =
    StateNotifierProvider.autoDispose<PostFormController, PostFormState>(
  (ref) => PostFormController(ref),
);

class PostFormController extends StateNotifier<PostFormState> {
  PostFormController(this._ref) : super(const PostFormState());

  final Ref _ref;

  PostRepository get _repo => _ref.read(postRepositoryProvider);

  /// Create a new post on behalf of the chosen [author] profile.
  /// Returns true on success; otherwise [PostFormState.error] holds a
  /// user-facing message.
  Future<bool> createPost({
    required ProfileModel author,
    required String content,
    List<String> hashtags = const [],
    List<String> images = const [],
    String? listingId,
    PostVisibility visibility = PostVisibility.public,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearLastSaved: true,
    );

    // Client-side banned-hashtag pre-check. The DB enforces this again
    // via trigger; we do it here so the user sees instant feedback rather
    // than waiting for a round-trip and a generic "check_violation" error.
    final banned =
        _ref.read(bannedHashtagsProvider).asData?.value;
    if (banned != null) {
      final offender = banned.firstBlocked(hashtags);
      if (offender != null) {
        state = state.copyWith(
          isSubmitting: false,
          error: 'The hashtag "#$offender" isn\'t allowed.',
        );
        return false;
      }
    }

    final neighborhoodId =
        _ref.read(sohoNeighborhoodIdProvider).asData?.value;
    if (neighborhoodId == null) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Neighborhood data is still loading. Try again in a moment.',
      );
      return false;
    }

    try {
      final result = await _repo.create(
        authorProfileId: author.id,
        neighborhoodId: neighborhoodId,
        content: content,
        hashtags: hashtags,
        images: images,
        listingId: listingId,
        visibility: visibility,
      );
      return result.fold(
        onOk: (post) {
          state = PostFormState(lastSaved: post);
          _ref.invalidate(neighborhoodPostsProvider);
          _ref.invalidate(postsByAuthorProvider(author.id));
          return true;
        },
        onErr: (failure) {
          AppLogger.w(
            'createPost failed: ${failure.message}',
            tag: 'posts',
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
        'createPost threw',
        tag: 'posts',
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

  /// Soft delete a post (sets is_removed=true). Author or admin only.
  Future<bool> deletePost(String id, {String? authorIdToInvalidate}) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    final result = await _repo.softDelete(id);
    return result.fold(
      onOk: (_) {
        state = const PostFormState();
        _ref.invalidate(neighborhoodPostsProvider);
        if (authorIdToInvalidate != null) {
          _ref.invalidate(postsByAuthorProvider(authorIdToInvalidate));
        }
        _ref.invalidate(postByIdProvider(id));
        return true;
      },
      onErr: (failure) {
        AppLogger.w('deletePost failed: ${failure.message}', tag: 'posts');
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

  String _humanize(Failure f) {
    return switch (f) {
      UnauthenticatedFailure() =>
        'Your session expired. Sign in again to keep posting.',
      UnauthorizedFailure() =>
        "You don't have permission to do that.",
      ValidationFailure() => f.message,
      ConflictFailure() => f.message,
      _ => f.message,
    };
  }
}
