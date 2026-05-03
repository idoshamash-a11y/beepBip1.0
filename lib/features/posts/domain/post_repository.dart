import '../../../core/result/result.dart';
import '../models/post_model.dart';

/// Domain-facing contract for posts. Implementations live in `data/`;
/// controllers and screens depend only on this interface so the data
/// source is swappable for tests / future migration.
abstract class PostRepository {
  // --- Reads ----------------------------------------------------------------

  /// Posts visible in a given neighborhood, newest first. Server-side RLS
  /// filters out expired and removed rows for non-owners; this method
  /// doesn't apply additional filters so owners see their own drafts /
  /// expired posts in the same feed call.
  Future<Result<List<Post>>> listForNeighborhood({
    required String neighborhoodId,
    int limit = 50,
  });

  /// Every post authored by [profileId], regardless of expiry / removal.
  /// Used by "My posts" surfaces.
  Future<Result<List<Post>>> listForAuthor(String profileId);

  /// Single post by id. Returns null on the Ok branch when RLS hides the
  /// row (or it's deleted) — distinct from a transport / server error
  /// (Err branch).
  Future<Result<Post?>> getById(String id);

  // --- Writes ---------------------------------------------------------------

  /// Insert a new post. Returns the persisted row with server-generated
  /// fields (id, expires_at default, hashtag normalization). [authorProfileId]
  /// must be a profile the caller owns; RLS rejects otherwise.
  ///
  /// [visibility] controls whether the post surfaces in the neighborhood
  /// discovery feeds. Defaults to public.
  Future<Result<Post>> create({
    required String authorProfileId,
    required String neighborhoodId,
    required String content,
    List<String> hashtags = const [],
    List<String> images = const [],
    String? listingId,
    PostVisibility visibility = PostVisibility.public,
  });

  /// Soft delete: sets `is_removed = true` rather than dropping the row.
  /// Preserves audit trail and the FK from any moderation references.
  Future<Result<void>> softDelete(String id);
}
