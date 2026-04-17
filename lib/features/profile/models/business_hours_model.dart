class BusinessHoursModel {
  final String id;
  final String businessProfileId;
  final int dayOfWeek; // 0=Sunday, 6=Saturday
  final String? openTime; // Format: "HH:mm"
  final String? closeTime; // Format: "HH:mm"
  final bool isClosed;
  final DateTime createdAt;

  BusinessHoursModel({
    required this.id,
    required this.businessProfileId,
    required this.dayOfWeek,
    this.openTime,
    this.closeTime,
    this.isClosed = false,
    required this.createdAt,
  });

  String get dayName {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[dayOfWeek];
  }

  String get hoursDisplay {
    if (isClosed) return 'Closed';
    if (openTime != null && closeTime != null) {
      return '$openTime - $closeTime';
    }
    return 'Not set';
  }

  factory BusinessHoursModel.fromJson(Map<String, dynamic> json) {
    return BusinessHoursModel(
      id: json['id'] as String,
      businessProfileId: json['business_profile_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      openTime: json['open_time'] as String?,
      closeTime: json['close_time'] as String?,
      isClosed: json['is_closed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_profile_id': businessProfileId,
      'day_of_week': dayOfWeek,
      'open_time': openTime,
      'close_time': closeTime,
      'is_closed': isClosed,
      'created_at': createdAt.toIso8601String(),
    };
  }

  BusinessHoursModel copyWith({
    String? id,
    String? businessProfileId,
    int? dayOfWeek,
    String? openTime,
    String? closeTime,
    bool? isClosed,
    DateTime? createdAt,
  }) {
    return BusinessHoursModel(
      id: id ?? this.id,
      businessProfileId: businessProfileId ?? this.businessProfileId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      isClosed: isClosed ?? this.isClosed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
