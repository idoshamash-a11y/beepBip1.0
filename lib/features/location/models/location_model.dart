class LocationModel {
  final String id;
  final String profileId;
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final bool isPrimary;
  final String? locationName;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocationModel({
    required this.id,
    required this.profileId,
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.isPrimary = false,
    this.locationName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postal_code'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      locationName: json['location_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'is_primary': isPrimary,
      'location_name': locationName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LocationModel copyWith({
    String? id,
    String? profileId,
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    bool? isPrimary,
    String? locationName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocationModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      isPrimary: isPrimary ?? this.isPrimary,
      locationName: locationName ?? this.locationName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
