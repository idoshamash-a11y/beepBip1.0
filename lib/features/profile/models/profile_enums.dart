enum ProfileType {
  personal,
  business;

  String get displayName {
    switch (this) {
      case ProfileType.personal:
        return 'Personal';
      case ProfileType.business:
        return 'Business';
    }
  }

  static ProfileType fromString(String value) {
    return ProfileType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ProfileType.personal,
    );
  }
}

enum SubscriptionTier {
  free,
  businessPro;

  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.businessPro:
        return 'Business Pro';
    }
  }

  /// Value stored in the Postgres `subscription_tier` enum.
  /// Keep in sync with `supabase/migrations/20260417180001_enums.sql`.
  String get databaseValue {
    switch (this) {
      case SubscriptionTier.free:
        return 'free';
      case SubscriptionTier.businessPro:
        return 'business_pro';
    }
  }

  static SubscriptionTier fromString(String value) {
    switch (value) {
      case 'free':
        return SubscriptionTier.free;
      case 'business_pro':
        return SubscriptionTier.businessPro;
      default:
        return SubscriptionTier.free;
    }
  }
}

enum VisibilityStatus {
  open,
  closed;

  String get displayName {
    switch (this) {
      case VisibilityStatus.open:
        return 'Open (Visible on Map)';
      case VisibilityStatus.closed:
        return 'Closed (Hidden)';
    }
  }

  String get description {
    switch (this) {
      case VisibilityStatus.open:
        return 'Your profile will be visible to other users';
      case VisibilityStatus.closed:
        return 'Your profile will be hidden from other users';
    }
  }

  static VisibilityStatus fromString(String value) {
    return VisibilityStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => VisibilityStatus.closed,
    );
  }
}

enum LocationSharing {
  dontShare,
  visibleWithoutLocation,
  visibleWithLocation;

  String get displayName {
    switch (this) {
      case LocationSharing.dontShare:
        return "Don't Share";
      case LocationSharing.visibleWithoutLocation:
        return 'Visible Without Location';
      case LocationSharing.visibleWithLocation:
        return 'Visible With Location';
    }
  }

  String get description {
    switch (this) {
      case LocationSharing.dontShare:
        return 'Your profile will not appear on the map';
      case LocationSharing.visibleWithoutLocation:
        return 'Your profile appears on map without exact coordinates';
      case LocationSharing.visibleWithLocation:
        return 'Your profile and exact location are visible';
    }
  }

  String get databaseValue {
    switch (this) {
      case LocationSharing.dontShare:
        return 'dont_share';
      case LocationSharing.visibleWithoutLocation:
        return 'visible_without_location';
      case LocationSharing.visibleWithLocation:
        return 'visible_with_location';
    }
  }

  static LocationSharing fromString(String value) {
    switch (value) {
      case 'dont_share':
        return LocationSharing.dontShare;
      case 'visible_without_location':
        return LocationSharing.visibleWithoutLocation;
      case 'visible_with_location':
        return LocationSharing.visibleWithLocation;
      default:
        return LocationSharing.dontShare;
    }
  }
}
