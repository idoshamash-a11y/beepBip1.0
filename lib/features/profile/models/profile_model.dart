import 'profile_enums.dart';

class ProfileModel {
  final String id;
  final String userId;
  final ProfileType profileType;
  final SubscriptionTier subscriptionTier;
  final VisibilityStatus visibilityStatus;
  final LocationSharing locationSharing;
  final bool isProfileComplete;

  /// Trust signal: admin has marked this profile as identity-verified.
  /// Drives the small "Verified" badge on the business page hero.
  final bool isVerified;

  /// Among the first 100 SoHo businesses (MVP §3.6); shown as a chip on the
  /// business page hero.
  final bool isFoundingBusiness;

  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileModel({
    required this.id,
    required this.userId,
    required this.profileType,
    this.subscriptionTier = SubscriptionTier.free,
    this.visibilityStatus = VisibilityStatus.open,
    this.locationSharing = LocationSharing.dontShare,
    this.isProfileComplete = false,
    this.isVerified = false,
    this.isFoundingBusiness = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      profileType: ProfileType.fromString(json['profile_type'] as String),
      subscriptionTier: SubscriptionTier.fromString(
        json['subscription_tier'] as String? ?? 'free',
      ),
      visibilityStatus: VisibilityStatus.fromString(
        json['visibility_status'] as String? ?? 'open',
      ),
      locationSharing: LocationSharing.fromString(
        json['location_sharing'] as String? ?? 'dont_share',
      ),
      isProfileComplete: json['is_profile_complete'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      isFoundingBusiness: json['is_founding_business'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'profile_type': profileType.name,
      'subscription_tier': subscriptionTier.databaseValue,
      'visibility_status': visibilityStatus.name,
      'location_sharing': locationSharing.databaseValue,
      'is_profile_complete': isProfileComplete,
      'is_verified': isVerified,
      'is_founding_business': isFoundingBusiness,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? userId,
    ProfileType? profileType,
    SubscriptionTier? subscriptionTier,
    VisibilityStatus? visibilityStatus,
    LocationSharing? locationSharing,
    bool? isProfileComplete,
    bool? isVerified,
    bool? isFoundingBusiness,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      profileType: profileType ?? this.profileType,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      visibilityStatus: visibilityStatus ?? this.visibilityStatus,
      locationSharing: locationSharing ?? this.locationSharing,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isVerified: isVerified ?? this.isVerified,
      isFoundingBusiness: isFoundingBusiness ?? this.isFoundingBusiness,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
