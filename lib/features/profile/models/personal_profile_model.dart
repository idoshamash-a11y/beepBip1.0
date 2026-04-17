class PersonalProfileModel {
  final String id;
  final String name;
  final String? phone;
  final String? photoUrl;
  final String? bio;
  final List<String> interests;
  final DateTime? dateOfBirth;
  final String? gender;
  final DateTime createdAt;
  final DateTime updatedAt;

  PersonalProfileModel({
    required this.id,
    required this.name,
    this.phone,
    this.photoUrl,
    this.bio,
    this.interests = const [],
    this.dateOfBirth,
    this.gender,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PersonalProfileModel.fromJson(Map<String, dynamic> json) {
    return PersonalProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      photoUrl: json['photo_url'] as String?,
      bio: json['bio'] as String?,
      interests: json['interests'] != null
          ? List<String>.from(json['interests'] as List)
          : [],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'photo_url': photoUrl,
      'bio': bio,
      'interests': interests,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PersonalProfileModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? photoUrl,
    String? bio,
    List<String>? interests,
    DateTime? dateOfBirth,
    String? gender,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PersonalProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
