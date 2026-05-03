/// One row in `public.business_profiles`. The schema is the source of truth
/// — see `supabase/migrations/20260417180002_users_and_profiles.sql`.
///
/// `cover_url`, `hashtags`, and `social_handles` exist on the table but were
/// not surfaced on the Dart side until the Business Page MVP. They power the
/// hero / chips / "follow us on" sections of [BusinessPageScreen].
class BusinessProfileModel {
  final String id;
  final String businessName;
  final String? logoUrl;
  final String? coverUrl;
  final String? description;
  final String? category;
  final List<String> services;

  /// Up to 5 "signature" hashtags shown as chips on the page hero. Stored
  /// lowercase + alphanumerics-with-underscores via the
  /// `business_profiles_normalize_hashtags` trigger.
  final List<String> hashtags;

  /// Free-form social handle map. Conventional keys: `instagram`, `tiktok`,
  /// `x`, `website`. We deliberately keep this a `Map<String, String>` so the
  /// schema can grow without a Dart-side enum coupling.
  final Map<String, String> socialHandles;

  final String? website;
  final String? phone;
  final String? email;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessProfileModel({
    required this.id,
    required this.businessName,
    this.logoUrl,
    this.coverUrl,
    this.description,
    this.category,
    this.services = const [],
    this.hashtags = const [],
    this.socialHandles = const {},
    this.website,
    this.phone,
    this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessProfileModel.fromJson(Map<String, dynamic> json) {
    List<String> stringList(dynamic v) {
      if (v == null) return const [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    Map<String, String> stringMap(dynamic v) {
      if (v == null) return const {};
      if (v is Map) {
        // Coerce values to strings; the JSONB column may legitimately hold
        // null entries (e.g. while a handle is being cleared) — drop those.
        final out = <String, String>{};
        v.forEach((key, value) {
          if (value == null) return;
          out[key.toString()] = value.toString();
        });
        return out;
      }
      return const {};
    }

    return BusinessProfileModel(
      id: json['id'] as String,
      businessName: json['business_name'] as String,
      logoUrl: json['logo_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      services: stringList(json['services']),
      hashtags: stringList(json['hashtags']),
      socialHandles: stringMap(json['social_handles']),
      website: json['website'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_name': businessName,
      'logo_url': logoUrl,
      'cover_url': coverUrl,
      'description': description,
      'category': category,
      'services': services,
      'hashtags': hashtags,
      'social_handles': socialHandles,
      'website': website,
      'phone': phone,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  BusinessProfileModel copyWith({
    String? id,
    String? businessName,
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessProfileModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      logoUrl: logoUrl ?? this.logoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      category: category ?? this.category,
      services: services ?? this.services,
      hashtags: hashtags ?? this.hashtags,
      socialHandles: socialHandles ?? this.socialHandles,
      website: website ?? this.website,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
