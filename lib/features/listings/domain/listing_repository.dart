import '../../../core/result/result.dart';
import '../models/listing_enums.dart';
import '../models/listing_model.dart';

/// Domain-facing contract for everything related to listings. Implementations
/// live in `data/`; controllers and screens should only depend on this
/// interface so we can swap the data source (mock, GraphQL, Edge Function,
/// etc.) without touching the UI.
abstract class ListingRepository {
  // --- Reads ----------------------------------------------------------------

  /// Active listings in a given neighborhood, newest first. RLS policy
  /// `listings_select_active` enforces that only `status = 'active'` rows are
  /// visible to non-owners; this method does NOT filter by status itself so
  /// that owners (who can see their own drafts) get a consistent feed.
  Future<Result<List<Listing>>> listForNeighborhood({
    required String neighborhoodId,
    int limit = 50,
  });

  /// Every listing owned by [profileId], regardless of status. Used by the
  /// "My listings" view for business owners. RLS policy
  /// `listings_write_owner` allows the caller to see their own non-active
  /// rows here.
  Future<Result<List<Listing>>> listForOwner(String profileId);

  /// Single listing by id. Returns `null` (Ok branch) if the row is not
  /// visible (RLS denied, deleted) — distinct from a transport / server
  /// failure (Err branch).
  Future<Result<Listing?>> getById(String id);

  // --- Writes ---------------------------------------------------------------

  /// Insert a new listing. Returns the persisted row with server-generated
  /// fields populated (id, timestamps, hashtag normalization).
  Future<Result<Listing>> create({
    required String profileId,
    required String neighborhoodId,
    required ListingType type,
    required String title,
    required int priceCents,
    String? description,
    String currency = 'USD',
    int? durationMinutes,
    int? capacity,
    int? stock,
    List<String> hashtags = const [],
    List<String> images = const [],
    ListingStatus status = ListingStatus.draft,
    DateTime? startsAt,
    DateTime? endsAt,
  });

  /// Update fields on an existing listing. Only non-null fields are written;
  /// null skips the column rather than overwriting it. To clear a nullable
  /// column, pass an explicit empty string / list.
  Future<Result<Listing>> update({
    required String id,
    ListingType? type,
    String? title,
    String? description,
    int? priceCents,
    String? currency,
    int? durationMinutes,
    int? capacity,
    int? stock,
    List<String>? hashtags,
    List<String>? images,
    ListingStatus? status,
    DateTime? startsAt,
    DateTime? endsAt,
  });

  /// Hard delete. RLS will reject if the caller doesn't own the row. We
  /// could prefer a soft-delete (`status = 'removed'`) once we have
  /// downstream references like reviews and bookings; for V1 hard-delete is
  /// fine because nothing else points at listings yet.
  Future<Result<void>> delete(String id);
}
