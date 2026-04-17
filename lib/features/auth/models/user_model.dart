class UserModel {
  final String id;
  final String serialId;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSeenAt;
  final bool isActive;

  UserModel({
    required this.id,
    required this.serialId,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.lastSeenAt,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      serialId: json['serial_id'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serial_id': serialId,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  UserModel copyWith({
    String? id,
    String? serialId,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeenAt,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      serialId: serialId ?? this.serialId,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
