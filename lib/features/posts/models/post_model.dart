/// Whether a post surfaces in the neighborhood discovery surfaces (feed,
/// map, search) or only loads when accessed by direct id.
///
///   * [PostVisibility.public]   — default. Appears everywhere a non-author
///     can see neighborhood activity. RLS policy `posts_select_active`
///     returns it to anyone signed in (subject to expiry / removal).
///   * [PostVisibility.unlisted] — does not appear in any discovery surface.
///     Only the author and people with the direct post id can fetch it.
///     Useful for "share this to a small group" or QA / staging posts.
///
/// We deliberately avoid "private" because the row remains reachable by id;
/// the schema does not (and will not, in V1) implement a friend graph that
/// would give "private" a stronger meaning.
enum PostVisibility {
  public,
  unlisted;

  String get databaseValue => switch (this) {
        PostVisibility.public => 'public',
        PostVisibility.unlisted => 'unlisted',
      };

  String get displayName => switch (this) {
        PostVisibility.public => 'Public',
        PostVisibility.unlisted => 'Unlisted',
      };

  /// One-line description shown under the pill so the user understands the
  /// trade-off before tapping.
  String get tagline => switch (this) {
        PostVisibility.public =>
          'Anyone in SoHo can see this in the feed and on the map.',
        PostVisibility.unlisted =>
          "Hidden from the feed, map, and search. Only people you share the link with see it.",
      };

  static PostVisibility fromString(String? value) {
    return switch (value) {
      'unlisted' => PostVisibility.unlisted,
      _ => PostVisibility.public,
    };
  }
}

/// One row in `public.posts`. Schema is the source of truth — see
/// `supabase/migrations/20260417180008_posts_and_messaging.sql`
/// and `…20260418000001_posts_visibility.sql`.
///
/// Posts are the lightweight "social surface" of the app (MVP §3.7) — they
/// announce activity, link to listings, and **auto-expire after 72 hours**
/// by DB default. They are *not* an Instagram feed; there is no follow
/// graph, no algorithmic ranking, no infinite scroll. Hashtags help
/// discovery as taxonomy, not as a feed format.
class Post {
  final String id;

  /// Profile (personal or business) that authored the post. NB: not the auth
  /// user id — a single user with both a personal and a business profile
  /// must pick one when posting (the form surfaces a switcher).
  final String authorProfileId;

  final String neighborhoodId;

  /// Optional link to a listing the post is announcing / promoting. The
  /// link survives the listing's lifetime via FK ON DELETE SET NULL.
  final String? listingId;

  /// 1–500 chars (DB-enforced). The form validates this before submit.
  final String content;

  /// Up to 4 image URLs (DB-enforced). Each URL points at a watermarked
  /// JPEG in the `user-uploads` Supabase Storage bucket; the upload is
  /// performed by `ImageUploadService` in the post-creation screen.
  final List<String> images;

  /// Up to 5 hashtags (DB-enforced). Stored lowercase / normalized via
  /// trigger. Banned tags rejected via trigger; client also blocks them
  /// for snappy UX.
  final List<String> hashtags;

  /// When this post stops being visible in `posts_select_active`. Default
  /// is `created_at + 72h`. Owners can still see their own expired posts.
  final DateTime expiresAt;

  /// Soft-delete flag. Author or admin sets it to true; the row stays for
  /// audit but is hidden from non-owners by RLS.
  final bool isRemoved;

  /// Discovery-surface inclusion. See [PostVisibility].
  final PostVisibility visibility;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Post({
    required this.id,
    required this.authorProfileId,
    required this.neighborhoodId,
    this.listingId,
    required this.content,
    this.images = const [],
    this.hashtags = const [],
    required this.expiresAt,
    this.isRemoved = false,
    this.visibility = PostVisibility.public,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    List<String> stringList(dynamic v) {
      if (v == null) return const [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    return Post(
      id: json['id'] as String,
      authorProfileId: json['author_profile_id'] as String,
      neighborhoodId: json['neighborhood_id'] as String,
      listingId: json['listing_id'] as String?,
      content: json['content'] as String,
      images: stringList(json['images']),
      hashtags: stringList(json['hashtags']),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isRemoved: json['is_removed'] as bool? ?? false,
      visibility: PostVisibility.fromString(json['visibility'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// True when [expiresAt] is in the past. Owners may still see their own
  /// expired posts (the schema's RLS policy keeps owner-visibility); for
  /// non-owners these are filtered server-side.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Time remaining until [expiresAt], or [Duration.zero] if expired.
  Duration get timeRemaining {
    final delta = expiresAt.difference(DateTime.now());
    return delta.isNegative ? Duration.zero : delta;
  }

  Post copyWith({
    String? id,
    String? authorProfileId,
    String? neighborhoodId,
    String? listingId,
    String? content,
    List<String>? images,
    List<String>? hashtags,
    DateTime? expiresAt,
    bool? isRemoved,
    PostVisibility? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      id: id ?? this.id,
      authorProfileId: authorProfileId ?? this.authorProfileId,
      neighborhoodId: neighborhoodId ?? this.neighborhoodId,
      listingId: listingId ?? this.listingId,
      content: content ?? this.content,
      images: images ?? this.images,
      hashtags: hashtags ?? this.hashtags,
      expiresAt: expiresAt ?? this.expiresAt,
      isRemoved: isRemoved ?? this.isRemoved,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
