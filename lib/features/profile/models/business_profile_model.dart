class BusinessProfileModel {
  final String id;
  final String businessName;
  final String? logoUrl;
  final String? description;
  final String? category;
  final List<String> services;
  final String? website;
  final String? phone;
  final String? email;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessProfileModel({
    required this.id,
    required this.businessName,
    this.logoUrl,
    this.description,
    this.category,
    this.services = const [],
    this.website,
    this.phone,
    this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessProfileModel.fromJson(Map<String, dynamic> json) {
    return BusinessProfileModel(
      id: json['id'] as String,
      businessName: json['business_name'] as String,
      logoUrl: json['logo_url'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      services: json['services'] != null
          ? List<String>.from(json['services'] as List)
          : [],
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
      'description': description,
      'category': category,
      'services': services,
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
    String? description,
    String? category,
    List<String>? services,
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
      description: description ?? this.description,
      category: category ?? this.category,
      services: services ?? this.services,
      website: website ?? this.website,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
