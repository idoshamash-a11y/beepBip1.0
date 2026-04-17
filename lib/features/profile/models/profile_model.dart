import 'profile_enums.dart';

class ProfileModel {
  final String id;
  final String userId;
  final ProfileType profileType;
  final SubscriptionTier subscriptionTier;
  final VisibilityStatus visibilityStatus;
  final LocationSharing locationSharing;
  final bool isProfileComplete;
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
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'profile_type': profileType.name,
      'subscription_tier': subscriptionTier.name,
      'visibility_status': visibilityStatus.name,
      'location_sharing': locationSharing.databaseValue,
      'is_profile_complete': isProfileComplete,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
