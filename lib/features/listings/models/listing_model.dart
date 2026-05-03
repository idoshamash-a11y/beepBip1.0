import 'listing_enums.dart';

/// One row in `public.listings`. The schema is the source of truth — see
/// `supabase/migrations/20260417180005_listings.sql`. Field names use Dart
/// camelCase; serialization handles the snake_case mapping.
///
/// Pricing convention: prices live in **cents** in the DB and on the wire.
/// All UI conversions to/from a decimal "$12.50" representation happen at
/// the form boundary, never in this model.
class Listing {
  final String id;
  final String profileId;
  final String neighborhoodId;
  final ListingType type;
  final String title;
  final String? description;
  final int priceCents;
  final String currency;

  /// Service-specific.
  final int? durationMinutes;

  /// Event-specific (required for events at the DB level).
  final int? capacity;

  /// Item-specific.
  final int? stock;

  final List<String> images;
  final List<String> hashtags;
  final ListingStatus status;

  /// Event start. Required for [ListingType.event] (DB constraint).
  final DateTime? startsAt;

  /// Event end. Required for [ListingType.event] (DB constraint:
  /// ends_at >= starts_at).
  final DateTime? endsAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Listing({
    required this.id,
    required this.profileId,
    required this.neighborhoodId,
    required this.type,
    required this.title,
    this.description,
    required this.priceCents,
    this.currency = 'USD',
    this.durationMinutes,
    this.capacity,
    this.stock,
    this.images = const [],
    this.hashtags = const [],
    this.status = ListingStatus.draft,
    this.startsAt,
    this.endsAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    List<String> stringList(dynamic v) {
      if (v == null) return const [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    DateTime? maybeDate(dynamic v) {
      if (v == null) return null;
      return DateTime.parse(v as String);
    }

    return Listing(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      neighborhoodId: json['neighborhood_id'] as String,
      type: ListingType.fromString(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      priceCents: (json['price_cents'] as num).toInt(),
      currency: json['currency'] as String? ?? 'USD',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      capacity: (json['capacity'] as num?)?.toInt(),
      stock: (json['stock'] as num?)?.toInt(),
      images: stringList(json['images']),
      hashtags: stringList(json['hashtags']),
      status: ListingStatus.fromString(
        json['status'] as String? ?? 'draft',
      ),
      startsAt: maybeDate(json['starts_at']),
      endsAt: maybeDate(json['ends_at']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convenience: price expressed in major units (e.g. dollars).
  double get priceDollars => priceCents / 100.0;

  /// "$ 12.50" style label. Currency-symbol mapping is intentionally tiny;
  /// expand once we add multi-currency support (FOLLOWUPS).
  String get priceLabel {
    final amount = priceDollars.toStringAsFixed(2);
    final symbol = currency == 'USD' ? '\$' : '$currency ';
    return '$symbol$amount';
  }

  Listing copyWith({
    String? id,
    String? profileId,
    String? neighborhoodId,
    ListingType? type,
    String? title,
    String? description,
    int? priceCents,
    String? currency,
    int? durationMinutes,
    int? capacity,
    int? stock,
    List<String>? images,
    List<String>? hashtags,
    ListingStatus? status,
    DateTime? startsAt,
    DateTime? endsAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Listing(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      neighborhoodId: neighborhoodId ?? this.neighborhoodId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      priceCents: priceCents ?? this.priceCents,
      currency: currency ?? this.currency,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      capacity: capacity ?? this.capacity,
      stock: stock ?? this.stock,
      images: images ?? this.images,
      hashtags: hashtags ?? this.hashtags,
      status: status ?? this.status,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
