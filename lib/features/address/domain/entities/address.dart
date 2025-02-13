class Address {
  final String id;
  final String userId;
  final String title;
  final String address;
  final double? lat;
  final double? lng;
  final bool isDefault;
  final DateTime createdAt;
  final String? city;
  final String? district;

  Address({
    required this.id,
    required this.userId,
    required this.title,
    required this.address,
    this.lat,
    this.lng,
    required this.isDefault,
    required this.createdAt,
    this.city,
    this.district,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
      isDefault: json['is_default'] == true,
      createdAt: DateTime.parse(json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      city: json['city']?.toString(),
      district: json['district']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'address': address,
      'lat': lat,
      'lng': lng,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'city': city,
      'district': district,
    };
  }

  Address copyWith({
    String? id,
    String? userId,
    String? title,
    String? address,
    double? lat,
    double? lng,
    bool? isDefault,
    DateTime? createdAt,
    String? city,
    String? district,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      city: city ?? this.city,
      district: district ?? this.district,
    );
  }

  factory Address.empty() => Address(
    id: '',
    userId: '',
    title: '',
    address: '',
    isDefault: false,
    createdAt: DateTime.now(),
    lat: 0,
    lng: 0,
    city: '',
    district: '',
  );
} 